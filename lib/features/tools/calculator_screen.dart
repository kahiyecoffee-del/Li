import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/formatters.dart';
import '../../domain/problem/calculator.dart';

/// A plain, reliable calculator (works offline). Shows a live result while
/// typing and keeps a short history.
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  String _expr = '';
  final _history = <(String, String)>[];

  double? get _preview {
    if (_expr.isEmpty) return null;
    try {
      final v = Calculator.evaluate(_expr, dotDecimal: true);
      return v.isFinite ? v : null;
    } on FormatException {
      return null;
    }
  }

  void _press(String k) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (k) {
        case 'C':
          _expr = '';
        case '⌫':
          if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
        case '=':
          final v = _preview;
          if (v != null) {
            final shown = ref.read(fmtProvider(Localizations.localeOf(context).toLanguageTag())).number(v, decimals: 8);
            _history.insert(0, (_expr, shown));
            if (_history.length > 20) _history.removeLast();
            _expr = _plain(v);
          }
        default:
          _expr += k;
      }
    });
  }

  /// Machine form of a number so it can be typed on ("1250.5").
  String _plain(double v) {
    final s = v.toStringAsFixed(8).replaceFirst(RegExp(r'\.?0+$'), '');
    return s == '-0' ? '0' : s;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    final preview = _preview;
    const keys = [
      ['C', '(', ')', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['%', '0', '.', '⌫'],
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.calcTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                reverse: true,
                padding: const EdgeInsets.all(Space.page),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        preview == null ? (_expr.isEmpty ? '0' : l.calcError) : fmt.number(preview, decimals: 8),
                        style: context.text.displaySmall?.copyWith(
                          color: preview == null && _expr.isNotEmpty ? context.semantic.muted : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(_expr, style: context.text.titleLarge?.copyWith(color: context.semantic.muted)),
                  ),
                  const SizedBox(height: Space.lg),
                  for (final (e, r) in _history)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: Space.xs),
                        child: Text('$e = $r', style: context.text.bodyMedium?.copyWith(color: context.semantic.muted)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.lg),
              child: Column(
                children: [
                  for (final row in keys)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Row(
                        children: [
                          for (final k in row)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: Space.xs),
                                child: _Key(label: k, onTap: () => _press(k)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _press('='),
                      child: Text('=', style: context.text.headlineSmall?.copyWith(color: context.colors.onPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final op = !RegExp(r'^[0-9.]$').hasMatch(label);
    return Material(
      color: op ? context.colors.primaryContainer : context.colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: SizedBox(
          height: 58,
          child: Center(
            child: Text(
              label,
              semanticsLabel: switch (label) {
                '⌫' => MaterialLocalizations.of(context).deleteButtonTooltip,
                'C' => MaterialLocalizations.of(context).clearButtonTooltip,
                _ => label,
              },
              style: context.text.titleLarge?.copyWith(
                color: op ? context.colors.onPrimaryContainer : context.colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
