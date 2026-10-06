import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/actions.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../core/widgets/mascot.dart';
import '../../domain/engines/meal_engine.dart';
import '../../domain/engines/recipe_library.dart';
import '../../domain/lio/lio_brain.dart';
import '../../domain/models/enums.dart';
import '../../domain/problem/problem_solver.dart';
import '../../domain/problem/quantities.dart';
import '../../domain/templates/message_templates.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../services/analytics/analytics_service.dart';
import '../plan/task_editor.dart';
import '../problem/problem_flow.dart';
import '../problem/solution_view.dart';
import 'lio_companion.dart';
import 'lio_facts.dart';

/// Lio as a guided helper: he asks, you tap a bubble or type a short answer,
/// and he replies from exact calculations and hand-written templates. No AI
/// model, so it is instant, offline and never makes things up.
class LioGuideScreen extends ConsumerStatefulWidget {
  const LioGuideScreen({super.key, this.initialText, this.topic, this.nonce});

  /// A problem typed on Home that the solver handed to Lio.
  final String? initialText;

  /// Jump straight to a topic ("write").
  final String? topic;

  /// Distinguishes two identical hand-offs in a row.
  final String? nonce;

  @override
  ConsumerState<LioGuideScreen> createState() => _LioGuideScreenState();
}

class _Msg {
  const _Msg(this.text, {this.user = false, this.rows = const [], this.note, this.copyable = false});
  final String text;
  final bool user;
  final List<(String, String)> rows;
  final String? note;
  final bool copyable;
}

class _Choice {
  const _Choice(this.label, this.onTap, {this.emoji}) : answer = null;

  /// A ready answer to the current question (a quick reply).
  const _Choice.answer(this.label, String this.answer) : onTap = _noop, emoji = null;

  final String label;
  final String? emoji;
  final VoidCallback onTap;
  final String? answer;

  static void _noop() {}
}

class _Question {
  const _Question({required this.onAnswer, this.keyboard = TextInputType.text, this.optional = false});
  final void Function(String) onAnswer;
  final TextInputType keyboard;
  final bool optional;
}

class _LioGuideScreenState extends ConsumerState<LioGuideScreen> {
  final _messages = <_Msg>[];
  var _choices = <_Choice>[];
  _Question? _question;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _rand = math.Random();
  String? _consumed;
  static final _handled = <String>{};

  AppLocalizations get l => context.l10n;
  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _root(greet: true);
      _consumeHandOff();
    });
  }

  @override
  void didUpdateWidget(covariant LioGuideScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _consumeHandOff();
    });
  }

  void _consumeHandOff() {
    final key = '${widget.initialText}|${widget.topic}|${widget.nonce}';
    if (key == _consumed || (widget.initialText == null && widget.topic == null)) return;
    _consumed = key;
    if (widget.nonce != null && !_handled.add(key)) return;
    if (widget.topic == 'write') {
      _user(l.quickWrite);
      _write();
    } else if (widget.initialText != null && widget.initialText!.trim().isNotEmpty) {
      _free(widget.initialText!);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- basics

  void _say(String text, {List<(String, String)> rows = const [], String? note, bool copyable = false}) {
    setState(() => _messages.add(_Msg(text, rows: rows, note: note, copyable: copyable)));
    _toEnd();
  }

  void _user(String text) {
    setState(() => _messages.add(_Msg(text, user: true)));
    _toEnd();
  }

  void _menu(String prompt, List<_Choice> choices) {
    _say(prompt);
    setState(() {
      _question = null;
      _choices = choices;
    });
  }

  void _ask(
    String prompt,
    void Function(String) onAnswer, {
    TextInputType keyboard = TextInputType.text,
    List<_Choice> quick = const [],
    bool optional = false,
  }) {
    _say(prompt);
    setState(() {
      _question = _Question(onAnswer: onAnswer, keyboard: keyboard, optional: optional);
      _choices = [...quick, if (optional) _Choice.answer(l.skip, '')];
    });
  }

  /// Asks for a number (money, count, percent). Re-asks on bad input.
  void _askNumber(
    String prompt,
    void Function(double) onValue, {
    List<_Choice> quick = const [],
    bool positive = true,
  }) {
    void handle(String v) {
      final q = Quantities.parse(v);
      final n = q.isNotEmpty ? q.first.value : Quantities.parseNumber(v.replaceAll(RegExp(r'[^\d.,]'), ''));
      if (n == null || (positive && n <= 0)) {
        _ask(l.gInvalidNumber, handle, keyboard: const TextInputType.numberWithOptions(decimal: true), quick: quick);
        return;
      }
      onValue(n);
    }

    _ask(prompt, handle, keyboard: const TextInputType.numberWithOptions(decimal: true), quick: quick);
  }

  void _answer(String text, {String? shown}) {
    final q = _question;
    _user(shown ?? text);
    setState(() {
      _question = null;
      _choices = const [];
    });
    q?.onAnswer(text);
  }

  void _tap(_Choice c) {
    HapticFeedback.selectionClick();
    final q = _question;
    _user(c.label);
    setState(() {
      _question = null;
      _choices = const [];
    });
    // Quick replies answer the pending question; other bubbles act.
    if (q != null && c.answer != null) {
      q.onAnswer(c.answer!);
    } else {
      c.onTap();
    }
  }

  void _submit() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    _input.clear();
    if (_question != null) {
      _answer(t);
    } else {
      _user(t);
      setState(() => _choices = const []);
      _free(t);
    }
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: Motion.normal, curve: Motion.curve);
      }
    });
  }

  List<_Choice> _after(VoidCallback again) => [_Choice(l.gSomethingElse, again), _Choice(l.gMainMenu, () => _root())];

  void _log(String kind) => unawaited(
    ref.read(servicesProvider).analytics.log(AnalyticsEvent.problemSolved, {'kind': kind, 'source': 'lio'}),
  );

  // ---------------------------------------------------------------- menus

  void _root({bool greet = false}) {
    final name = ref.read(profileProvider).value?.name ?? '';
    if (greet) _say(name.isEmpty ? l.homeHelloNoName : l.homeHello(name));
    _menu(l.aiEmptyTitle, [
      _Choice(l.quickMoney, _money, emoji: '💰'),
      _Choice(l.quickDecide, _decide, emoji: '🧠'),
      _Choice(l.quickFood, _food, emoji: '🍳'),
      _Choice(l.quickWrite, _write, emoji: '✍️'),
      _Choice(l.quickCalc, _calc, emoji: '🧮'),
      _Choice(l.gRemind, _remind, emoji: '⏰'),
      _Choice(l.gMood, _mood, emoji: '💛'),
      _Choice(l.exploreMyDay, _myDay, emoji: '☀️'),
    ]);
  }

  void _money() => _menu(l.gMoneyPrompt, [
    _Choice(l.gRunway, _runway),
    _Choice(l.gDiscount, _discount),
    _Choice(l.gSplit, _split),
    _Choice(l.gInstallment, _installment),
    _Choice(l.gUnitPrice, _unitPrice),
    _Choice(l.gVat, _vat),
    _Choice(l.gRaise, _raise),
    _Choice(l.gYearly, _yearly),
  ]);

  void _calc() => _menu(l.gCalcPrompt, [
    _Choice(l.gPercentOf, _percentOf),
    _Choice(l.gConvert, _convert),
    _Choice(l.gDaysUntil, _daysUntil),
    _Choice(l.gFuel, _fuel),
    _Choice(l.gOpenCalculator, () {
      context.push('/calc');
      _root();
    }),
  ]);

  // ---------------------------------------------------------------- answers

  void _solution(Solution s, VoidCallback again) {
    final t = describeSolution(s, l, ref.read(fmtProvider(Localizations.localeOf(context).toLanguageTag())));
    _say(t.headline, rows: t.rows, note: t.note);
    _log(s.kind);
    setState(() {
      _choices = [
        _Choice(l.save, () {
          saveProblem(
            context,
            ref,
            kind: s.kind,
            title: t.headline,
            summary: t.rows.map((r) => '${r.$1}: ${r.$2}').join(' · '),
            payload: {
              'details': [t.headline, ...t.rows.map((r) => '${r.$1}: ${r.$2}')],
            },
          );
          setState(() => _choices = _after(again));
        }, emoji: '🔖'),
        ..._after(again),
      ];
    });
  }

  void _runway() => _askNumber(
    l.qAmountLeft,
    (amount) => _askNumber(
      l.qDaysLeft,
      (days) => _solution(RunwaySolution(amount: amount, days: days.round(), currency: null, monthEnd: false), _money),
      quick: [
        _Choice(l.qMonthEnd, () {
          final now = DateTime.now();
          final days = DateTime(now.year, now.month + 1, 0).day - now.day + 1;
          _solution(RunwaySolution(amount: amount, days: days, currency: null, monthEnd: true), _money);
        }),
      ],
    ),
  );

  void _discount() => _askNumber(
    l.qPrice,
    (price) => _askNumber(
      l.qDiscountPct,
      (pct) => _solution(PriceChangeSolution(price: price, percent: pct, mode: PercentChange.discount), _money),
    ),
  );

  void _split() => _askNumber(
    l.qTotal,
    (total) => _askNumber(l.qPeople, (people) {
      if (people < 2) {
        _askNumber(l.qPeople, (p) => _tip(total, p.round()));
        return;
      }
      _tip(total, people.round());
    }),
  );

  void _tip(double total, int people) => _askNumber(
    l.qTip,
    (tip) => _solution(SplitSolution(total: total, people: people, tipPercent: tip), _money),
    positive: false,
    quick: [
      for (final t in [0, 5, 10, 15]) _Choice.answer(t == 0 ? l.qNoTip : '%$t', '$t'),
    ],
  );

  void _installment() => _askNumber(
    l.qMonthly,
    (monthly) => _askNumber(l.qMonths, (months) {
      void finish(double? cash) =>
          _solution(InstallmentSolution(monthly: monthly, months: months.round(), cashPrice: cash), _money);
      _ask(
        l.qCash,
        (v) {
          final n = Quantities.parseNumber(v.replaceAll(RegExp(r'[^\d.,]'), ''));
          finish(v.trim().isEmpty || n == null || n <= 0 ? null : n);
        },
        keyboard: const TextInputType.numberWithOptions(decimal: true),
        optional: true,
      );
    }),
  );

  void _unitPrice() {
    Quantity? sized(String v) =>
        Quantities.parse(v)
            .where((q) => const {Dim.volume, Dim.mass, Dim.length, Dim.count}.contains(q.dim))
            .firstOrNull;
    void askSize(String prompt, void Function(Quantity) next) {
      void handle(String v) {
        final q = sized(v);
        if (q == null || q.value <= 0) {
          _ask(l.qNeedUnit, handle);
          return;
        }
        next(q);
      }

      _ask(prompt, handle);
    }

    askSize(
      l.qSize1,
      (a) => _askNumber(
        l.qPrice1,
        (pa) => askSize(l.qSize2, (b) {
          if (b.unit!.dim != a.unit!.dim) {
            _say(l.qNeedUnit);
            _unitPrice();
            return;
          }
          _askNumber(
            l.qPrice2,
            (pb) => _solution(
              UnitPriceSolution(items: [UnitPriceItem(a.value, a.unit!, pa), UnitPriceItem(b.value, b.unit!, pb)]),
              _money,
            ),
          );
        }),
      ),
    );
  }

  void _vat() => _askNumber(
    l.qPrice,
    (price) => _askNumber(
      l.qVatRate,
      (rate) => _solution(PriceChangeSolution(price: price, percent: rate, mode: PercentChange.vat), _money),
      quick: [
        for (final r in [1, 10, 20]) _Choice.answer('%$r', '$r'),
      ],
    ),
  );

  void _raise() => _askNumber(
    l.qSalary,
    (salary) => _askNumber(
      l.qRaisePct,
      (pct) => _solution(PriceChangeSolution(price: salary, percent: pct, mode: PercentChange.raise), _money),
    ),
  );

  void _yearly() {
    void handle(String v) {
      final amounts = Quantities.parse(v).map((q) => q.value).where((x) => x > 0).toList();
      if (amounts.isEmpty) {
        _ask(l.gInvalidNumber, handle);
        return;
      }
      _solution(YearlySolution(monthlyAmounts: amounts), _money);
    }

    _ask(l.qSubs, handle, keyboard: TextInputType.text);
  }

  void _percentOf() => _askNumber(
    l.qNumber,
    (n) => _askNumber(l.qPercent, (p) => _solution(PercentOfSolution(base: n, percent: p), _calc)),
  );

  void _convert() {
    void handle(String v) {
      final r = problemSolver.solve(v.contains(RegExp(r'kaç|kac|to|in|=|\?')) ? v : '$v ?');
      if (r is ConvertSolution) {
        _solution(r, _calc);
      } else {
        _ask(l.gConvertFail, handle);
      }
    }

    _ask(l.qConvert, handle);
  }

  void _daysUntil() {
    void handle(String v) {
      final r = problemSolver.solve('$v ${_lang == 'tr' ? 'kaç gün var' : 'how many days until'}');
      final r2 = r is DaysUntilSolution ? r : problemSolver.solve('how many days until $v');
      if (r2 is DaysUntilSolution) {
        _solution(r2, _calc);
      } else {
        _ask(l.gDateFail, handle);
      }
    }

    _ask(l.qDate, handle);
  }

  void _fuel() => _askNumber(
    l.qKm,
    (km) => _askNumber(
      l.qConsumption,
      (lp) => _askNumber(
        l.qFuelPrice,
        (price) => _solution(FuelSolution(km: km, litresPer100: lp, pricePerLitre: price), _calc),
      ),
    ),
  );

  // ---------------------------------------------------------------- decide

  void _decide([List<String>? given]) {
    void withOptions(List<String> options) {
      final enc = options.map(Uri.encodeQueryComponent).join('|');
      _menu(options.join(' · '), [
        _Choice(l.gDecideCompare, () {
          context.push('/decide?o=$enc');
          _menu(l.aiEmptyTitle, _after(_decide));
        }, emoji: '⚖️'),
        _Choice(l.gCoin, () {
          final heads = _rand.nextBool();
          _say('${heads ? l.coinHeads : l.coinTails}${options.length == 2 ? ' → ${options[heads ? 0 : 1]}' : ''}');
          setState(() => _choices = _after(_decide));
        }, emoji: '🪙'),
        _Choice(l.gRandomPick, () {
          _say(l.randomPicked(options[_rand.nextInt(options.length)]));
          setState(() => _choices = _after(_decide));
        }, emoji: '🎲'),
      ]);
    }

    if (given != null && given.length >= 2) return withOptions(given);
    _say(l.gDecidePrompt);
    void handle(String v) {
      var options = ProblemSolver.splitOptions(v);
      if (options.length < 2) {
        options = v.split(RegExp(r'[,\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      if (options.length < 2) {
        _ask(l.decideNeedTwo, handle);
        return;
      }
      unawaited(ref.read(servicesProvider).analytics.log(AnalyticsEvent.decisionStarted, {'source': 'lio'}));
      withOptions(options.take(6).toList());
    }

    _ask(l.qOptions, handle);
  }

  // ---------------------------------------------------------------- food

  void _food() => _menu(l.gFoodPrompt, [
    _Choice(l.gCookWithWhatIHave, () => _ask(l.qIngredients, (v) => _recipes(_splitList(v)))),
    _Choice(l.gWhatToEat, _mealIdea),
    _Choice(l.gShoppingList, () {
      context.push('/shopping');
      _root();
    }),
    _Choice(l.gRecipes, () {
      context.push('/food');
      _root();
    }),
  ]);

  List<String> _splitList(String v) =>
      v.split(RegExp(r'\s*(?:,|\n|\sve\s|\sand\s)\s*')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  void _recipes(List<String> have) {
    final matches = bestForIngredients(RecipeLibrary.all(_lang), have);
    unawaited(
      ref.read(servicesProvider).analytics.log(AnalyticsEvent.recipeGenerated, {'source': 'lio', 'count': have.length}),
    );
    if (matches.isEmpty) {
      _say(l.recipeNoMatch);
      setState(() => _choices = _after(_food));
      return;
    }
    _say(
      l.recipeHeadline,
      rows: [
        for (final m in matches)
          (
            '${m.recipe.name} · ${l.recipeMinutes(m.recipe.prepMinutes)}',
            m.missing.isEmpty
                ? l.recipeHaveAll
                : l.recipeMissing(m.missing.map((x) => ingredientName(x, _lang)).join(', ')),
          ),
      ],
    );
    final missing = matches.first.missing.map((x) => ingredientName(x, _lang)).toList();
    setState(
      () => _choices = [
        if (missing.isNotEmpty)
          _Choice(l.addMissingToList, () async {
            await ref.read(actionsProvider).addShoppingItems(missing);
            if (mounted) _say(l.addedToList);
            setState(() => _choices = _after(_food));
          }, emoji: '🛒'),
        ..._after(_food),
      ],
    );
  }

  void _mealIdea() {
    final h = DateTime.now().hour;
    final type = h < 10 ? MealType.breakfast : (h < 15 ? MealType.lunch : MealType.dinner);
    final prefs = ref.read(profileProvider).value?.food;
    var pool = RecipeLibrary.all(_lang).where((r) => r.mealType == type).toList();
    if (prefs != null) {
      final ok = const MealEngine().eligible(pool, prefs);
      if (ok.isNotEmpty) pool = ok;
    }
    final r = pool[_rand.nextInt(pool.length)];
    _say(l.mealIdea(r.name, r.prepMinutes));
    setState(
      () => _choices = [
        _Choice(l.gAnotherIdea, _mealIdea, emoji: '🔁'),
        _Choice(l.gRecipes, () {
          context.push('/food');
          _root();
        }),
        _Choice(l.gMainMenu, () => _root()),
      ],
    );
  }

  // ---------------------------------------------------------------- write

  String _tplLabel(String id) => switch (id) {
    'birthday' => l.tplBirthday,
    'thanks' => l.tplThanks,
    'apology' => l.tplApology,
    'late' => l.tplLate,
    'leave' => l.tplLeave,
    'decline' => l.tplDecline,
    'congrats' => l.tplCongrats,
    'condolence' => l.tplCondolence,
    'payment' => l.tplPayment,
    'complaint' => l.tplComplaint,
    'job' => l.tplJob,
    _ => l.tplLandlord,
  };

  String _fieldQuestion(String id, TemplateField f) => switch (f) {
    TemplateField.name => l.fName,
    TemplateField.company => l.fCompany,
    TemplateField.when => id == 'late' ? l.fWhenLate : l.fWhenLeave,
    TemplateField.what => switch (id) {
      'thanks' => l.fWhatThanks,
      'apology' => l.fWhatApology,
      'leave' => l.fWhatLeave,
      'decline' => l.fWhatDecline,
      'congrats' => l.fWhatCongrats,
      'payment' => l.fWhatPayment,
      'complaint' => l.fWhatComplaint,
      'job' => l.fWhatJob,
      _ => l.fWhatLandlord,
    },
  };

  void _write() => _menu(l.gWritePrompt, [
    for (final t in MessageTemplates.all) _Choice(_tplLabel(t.id), () => _tone(t), emoji: t.emoji),
  ]);

  void _tone(MessageTemplate t, [Map<TemplateField, String>? known]) => _menu(l.qTone, [
    for (final (tone, label) in [(Tone.warm, l.toneWarm), (Tone.formal, l.toneFormal), (Tone.short, l.toneShort)])
      _Choice(label, () => known != null ? _compose(t, tone, known) : _fields(t, tone, 0, {})),
  ]);

  void _fields(MessageTemplate t, Tone tone, int i, Map<TemplateField, String> values) {
    if (i >= t.fields.length) return _compose(t, tone, values);
    final f = t.fields[i];
    _ask(_fieldQuestion(t.id, f), (v) {
      values[f] = v.trim();
      _fields(t, tone, i + 1, values);
    }, optional: f == TemplateField.name);
  }

  void _compose(MessageTemplate t, Tone tone, Map<TemplateField, String> values) {
    _say(l.writeResult);
    for (final v in t.variants(_lang, tone)) {
      _say(MessageTemplates.fill(v, values), copyable: true);
    }
    _log('write_${t.id}');
    setState(
      () => _choices = [
        _Choice(l.gOtherTone, () => _tone(t, values), emoji: '🎚️'),
        _Choice(l.gOtherMessage, _write, emoji: '✍️'),
        _Choice(l.gMainMenu, () => _root()),
      ],
    );
  }

  // ---------------------------------------------------------------- remind, mood, my day

  void _remind() => _ask(l.gRemindPrompt, (v) async {
    await showTaskEditor(context, title: v, day: DateTime.now());
    if (mounted) _root();
  });

  void _mood() => _menu(l.gMoodPrompt, [
    for (final (label, reply) in [
      (l.mTired, l.mTiredReply),
      (l.mStressed, l.mStressedReply),
      (l.mUnmotivated, l.mUnmotivatedReply),
      (l.mCantSleep, l.mCantSleepReply),
      (l.mLonely, l.mLonelyReply),
      (l.mVeryBad, l.mVeryBadReply),
    ])
      _Choice(label, () {
        _say(reply);
        setState(() => _choices = [_Choice(l.gInspire, _inspire, emoji: '✨'), _Choice(l.gMainMenu, () => _root())]);
      }),
  ]);

  void _inspire() {
    final lines = LioScript.inspirations(l);
    _say(lines[_rand.nextInt(lines.length)]);
    setState(() => _choices = [_Choice(l.gInspire, _inspire, emoji: '✨'), _Choice(l.gMainMenu, () => _root())]);
  }

  void _brain(String message) {
    final facts = buildLioFacts(ref.read, Localizations.localeOf(context));
    final r = LioBrain.reply(message, facts, l, inspirations: LioScript.inspirations(l));
    _say(r.text);
  }

  void _myDay() => _menu(l.gMyDayPrompt, [
    for (final label in [l.gTodayPlan, l.gSpendToday, l.gMyScore])
      _Choice(label, () {
        _brain(label);
        setState(() => _choices = _after(_myDay));
      }),
    _Choice(l.gOpenMyDay, () {
      context.push('/today');
      _root();
    }),
  ]);

  // ---------------------------------------------------------------- free text

  void _free(String text) {
    final r = problemSolver.solve(text);
    switch (r) {
      case final Solution s:
        _solution(s, () => _root());
      case ToolRoute(tool: ProblemTool.decide, :final options):
        _decide(options);
      case ToolRoute(tool: ProblemTool.recipe, :final options):
        _recipes(options);
      case ToolRoute(tool: ProblemTool.write):
        _write();
      case ToolRoute(tool: ProblemTool.reminder):
        unawaited(showTaskEditor(context, title: text, day: DateTime.now()).then((_) => mounted ? _root() : null));
      case AskLio():
        final services = ref.read(servicesProvider);
        final online = ref.read(onlineProvider).value ?? true;
        if (LioBrain.intentOf(text) != LioIntent.unknown) {
          _brain(text);
          setState(() => _choices = _after(() => _root()));
        } else if (services.aiEnabled && online) {
          context.go('/ai/chat?q=${Uri.encodeQueryComponent(text)}&send=1&n=${DateTime.now().microsecondsSinceEpoch}');
        } else {
          _menu(l.gNotUnderstood, _rootChoices());
        }
    }
  }

  List<_Choice> _rootChoices() => [
    _Choice(l.quickMoney, _money, emoji: '💰'),
    _Choice(l.quickDecide, _decide, emoji: '🧠'),
    _Choice(l.quickFood, _food, emoji: '🍳'),
    _Choice(l.quickWrite, _write, emoji: '✍️'),
    _Choice(l.quickCalc, _calc, emoji: '🧮'),
    _Choice(l.gMood, _mood, emoji: '💛'),
  ];

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final asking = _question != null;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Mascot(mood: MascotMood.happy, size: 34, float: false),
            const SizedBox(width: Space.sm),
            Text('Lio', style: context.text.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.gRestart,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _messages.clear();
                _choices = const [];
                _question = null;
              });
              _root();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.md),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final prevLio = i > 0 && !_messages[i - 1].user;
                  return FadeSlideIn(
                    child: _Bubble(msg: _messages[i], showAvatar: !_messages[i].user && !prevLio),
                  );
                },
              ),
            ),
            if (_choices.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.32),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(Space.page, Space.xs, Space.page, Space.sm),
                  child: Wrap(
                    spacing: Space.sm,
                    runSpacing: Space.sm,
                    children: [
                      for (final c in _choices)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 2 * Space.page),
                          child: ActionChip(
                            avatar: c.emoji == null ? null : Text(c.emoji!),
                            label: Text(c.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                            onPressed: () => _tap(c),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.page, Space.xs, Space.sm, 96),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      keyboardType: asking ? _question!.keyboard : TextInputType.text,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(hintText: asking ? l.gAnswerHint : l.gTypeHint),
                    ),
                  ),
                  IconButton(tooltip: l.aiSend, onPressed: _submit, icon: const Icon(Icons.send_rounded)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.showAvatar});
  final _Msg msg;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = msg.user;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
      padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      decoration: BoxDecoration(
        color: user ? context.colors.primary : context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(Radii.lg),
          topRight: const Radius.circular(Radii.lg),
          bottomLeft: Radius.circular(user ? Radii.lg : 4),
          bottomRight: Radius.circular(user ? 4 : Radii.lg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            msg.text,
            style: (msg.rows.isNotEmpty ? context.text.titleMedium : context.text.bodyLarge)?.copyWith(
              color: user ? context.colors.onPrimary : null,
            ),
          ),
          for (final (k, v) in msg.rows)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs + 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(k, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
                  ),
                  const SizedBox(width: Space.sm),
                  Flexible(
                    child: Text(
                      v,
                      textAlign: TextAlign.end,
                      style: context.text.labelLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ],
              ),
            ),
          if (msg.note != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(msg.note!, style: context.text.bodySmall?.copyWith(color: context.semantic.muted)),
            ),
          if (msg.copyable)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: msg.text));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(l.copy),
              ),
            ),
        ],
      ),
    );
    return Padding(
      padding: EdgeInsets.only(top: showAvatar || user ? Space.md : Space.xs),
      child: Row(
        mainAxisAlignment: user ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!user)
            SizedBox(
              width: 34,
              child: showAvatar ? const Mascot(mood: MascotMood.happy, size: 30, float: false) : null,
            ),
          if (!user) const SizedBox(width: Space.xs),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}
