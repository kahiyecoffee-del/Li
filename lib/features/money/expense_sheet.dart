import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/actions.dart';
import '../../app/ml_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/json.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/engines/receipt_parser.dart';
import '../../domain/models/enums.dart';
import '../../services/ai/ai_models.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/config/feature_flags.dart';

Future<void> showExpenseSheet(BuildContext context, {TransactionType type = TransactionType.expense}) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => ExpenseSheet(type: type),
    );

/// Quick entry: type "250 lunch" and the fields fill themselves. Parsing is
/// local first; the AI is only asked when the category can't be recognized.
class ExpenseSheet extends ConsumerStatefulWidget {
  const ExpenseSheet({super.key, this.type = TransactionType.expense, this.prefill});

  final TransactionType type;
  final ParsedReceipt? prefill;

  @override
  ConsumerState<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<ExpenseSheet> {
  final _smart = TextEditingController();
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  late TransactionType _type = widget.type;
  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = DateTime.now();
  String? _merchant;
  bool _parsingAi = false;
  bool _categoryTouched = false;
  Timer? _aiDebounce;

  @override
  void initState() {
    super.initState();
    final r = widget.prefill;
    if (r != null) {
      if (r.totalMinor != null) _amount.text = (r.totalMinor! / 100).toStringAsFixed(2);
      _merchant = r.merchant;
      _desc.text = r.merchant ?? '';
      _date = r.date ?? DateTime.now();
      _category =
          ref.read(localModelsNowProvider).expenseParser.categorizeText(r.merchant ?? '') ?? ExpenseCategory.food;
    }
  }

  @override
  void dispose() {
    _aiDebounce?.cancel();
    _smart.dispose();
    _amount.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _onSmart(String text) {
    final p = ref.read(localModelsNowProvider).expenseParser.parse(text);
    _aiDebounce?.cancel();
    if (p == null) return;
    setState(() {
      _amount.text = (p.amountMinor / 100).toStringAsFixed(p.amountMinor % 100 == 0 ? 0 : 2);
      _desc.text = p.description;
      _type = p.type;
      if (!_categoryTouched) _category = p.category;
    });
    if (!p.confident && p.description.isNotEmpty) {
      _aiDebounce = Timer(const Duration(milliseconds: 900), () => _aiCategorize(text));
    }
  }

  Future<void> _aiCategorize(String text) async {
    setState(() => _parsingAi = true);
    try {
      final r = await ref.read(servicesProvider).ai.task(AiTaskType.parseExpense, {'text': text});
      final cat = ExpenseCategory.values.where((c) => c.name == r.result['category']).firstOrNull;
      if (mounted && cat != null && !_categoryTouched) setState(() => _category = cat);
      final desc = J.strOrNull(r.result, 'description');
      if (mounted && desc != null && _desc.text.isEmpty) _desc.text = desc;
    } catch (_) {
      // Offline / no credits: the user simply picks a category.
    } finally {
      if (mounted) setState(() => _parsingAi = false);
    }
  }

  Future<void> _save() async {
    final minor = Money.parseMinor(_amount.text);
    if (minor == null || minor <= 0) {
      showSnack(context, context.l10n.errorInvalidInput);
      return;
    }
    await ref
        .read(actionsProvider)
        .addTransaction(
          amountMinor: minor,
          category: _category,
          description: _desc.text.trim(),
          date: _date,
          type: _type,
          merchant: _merchant,
          source: widget.prefill != null
              ? TransactionSource.receipt
              : (_smart.text.isNotEmpty ? TransactionSource.smartInput : TransactionSource.manual),
        );
    if (!mounted) return;
    Navigator.pop(context);
    showSnack(context, context.l10n.expenseSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final currency = ref.watch(profileProvider.select((p) => p.value?.currency ?? 'USD'));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(value: TransactionType.expense, label: Text(l.addExpense)),
                ButtonSegment(value: TransactionType.income, label: Text(l.addIncome)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: Space.lg),
            if (widget.prefill == null) ...[
              TextField(
                controller: _smart,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l.smartInputHint,
                  prefixIcon: const Icon(Icons.bolt_rounded),
                  suffixIcon: _parsingAi
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                  helperText: _parsingAi ? l.aiParsing : l.smartInputHelp,
                ),
                onChanged: _onSmart,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: Space.lg),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                    decoration: InputDecoration(labelText: l.amount, suffixText: currency),
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(DateTime.now().year - 2),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(fmt.dayMonth(_date)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.md),
            TextField(
              controller: _desc,
              decoration: InputDecoration(labelText: l.description),
            ),
            if (_type == TransactionType.expense) ...[
              const SizedBox(height: Space.lg),
              Text(l.category, style: context.text.titleSmall),
              const SizedBox(height: Space.sm),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: ExpenseCategory.values
                    .map(
                      (c) => ChoiceChip(
                        label: Text(l.expenseCategory(c)),
                        selected: _category == c,
                        onSelected: (_) => setState(() {
                          _category = c;
                          _categoryTouched = true;
                        }),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: Space.xl),
            FilledButton(onPressed: _save, child: Text(l.save)),
            if (widget.prefill == null && ref.watch(servicesProvider).flags.isEnabled(Feature.receiptOcr)) ...[
              const SizedBox(height: Space.sm),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await scanReceipt(context, ref);
                },
                icon: const Icon(Icons.document_scanner_outlined),
                label: Text(l.scanReceipt),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Receipt flow: photo → on-device OCR → heuristic parse → user review.
Future<void> scanReceipt(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    useRootNavigator: true,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.takePhoto),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.chooseFromGallery),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return;
  final image = await ImagePicker().pickImage(source: source, maxWidth: 2000, imageQuality: 85);
  if (image == null || !context.mounted) return;
  ParsedReceipt parsed;
  try {
    final text = await ref.read(servicesProvider).ocr.recognize(image.path);
    parsed = const ReceiptParser().parse(text, now: DateTime.now());
  } catch (_) {
    parsed = const ParsedReceipt();
  }
  unawaited(
    ref.read(servicesProvider).analytics.log(AnalyticsEvent.receiptScanned, {
      'found_total': parsed.totalMinor != null ? 1 : 0,
    }),
  );
  if (!context.mounted) return;
  if (parsed.isEmpty) {
    showSnack(context, l.receiptNothingFound);
    return showExpenseSheet(context);
  }
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (c) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.receiptReview, style: c.text.titleLarge),
              const SizedBox(height: Space.xs),
              Text(l.receiptReviewBody, style: c.text.bodySmall?.copyWith(color: c.semantic.muted)),
              if (parsed.items.isNotEmpty) ...[
                const SizedBox(height: Space.sm),
                Text(
                  '${l.receiptItems}: ${parsed.items.map((i) => i.name).take(6).join(', ')}',
                  style: c.text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: Space.md),
            ],
          ),
        ),
        Flexible(child: ExpenseSheet(prefill: parsed)),
      ],
    ),
  );
}
