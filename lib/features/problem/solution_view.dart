import '../../core/widgets/formatters.dart';
import '../../domain/problem/problem_solver.dart';
import '../../domain/problem/quantities.dart';
import '../../l10n/gen/app_localizations.dart';

/// A solved problem in words: one headline sentence, the numbers behind it,
/// and an optional note.
class SolutionText {
  const SolutionText(this.headline, this.rows, {this.note});
  final String headline;
  final List<(String, String)> rows;
  final String? note;
}

SolutionText describeSolution(Solution s, AppLocalizations l, Fmt fmt) {
  String m(double v, String? cur) => fmt.amount(v, currency: cur);
  String n(double v, [int d = 2]) => fmt.number(v, decimals: d);
  return switch (s) {
    RunwaySolution() => SolutionText(l.runwayHeadline(m(s.perDay, s.currency)), [
      (l.rowTotal, m(s.amount, s.currency)),
      (l.rowDays, '${s.days}'),
      (l.rowPerDay, m(s.perDay, s.currency)),
      if (s.days >= 7) (l.rowPerWeek, m(s.perWeek, s.currency)),
    ], note: s.monthEnd ? l.runwayMonthEnd(s.days) : null),
    PriceChangeSolution() => SolutionText(
      switch (s.mode) {
        PercentChange.discount => l.discountHeadline(m(s.result, s.currency)),
        PercentChange.vat => l.vatHeadline(m(s.result, s.currency)),
        PercentChange.raise => l.raiseHeadline(m(s.result, s.currency)),
      },
      [
        (l.rowPrice, m(s.price, s.currency)),
        ('%', n(s.percent)),
        (
          switch (s.mode) {
            PercentChange.discount => l.rowYouSave,
            PercentChange.vat => l.rowTax,
            PercentChange.raise => l.rowIncrease,
          },
          m(s.delta, s.currency),
        ),
      ],
    ),
    PercentOfSolution() => SolutionText(l.percentOfHeadline(n(s.percent), n(s.base), n(s.result)), const []),
    SplitSolution() => SolutionText(l.splitHeadline(m(s.perPerson, s.currency)), [
      (l.rowTotal, m(s.total, s.currency)),
      if (s.tipPercent > 0) (l.rowTip, '%${n(s.tipPercent)} · ${m(s.totalWithTip - s.total, s.currency)}'),
      (l.rowPeople, '${s.people}'),
      (l.rowPerPerson, m(s.perPerson, s.currency)),
    ]),
    InstallmentSolution() => SolutionText(
      s.extra == null
          ? l.installmentTotal(m(s.total, s.currency))
          : s.extra! > 0
          ? l.installmentMore(m(s.extra!, s.currency), n(s.extraPercent!, 1))
          : l.installmentNoMore,
      [
        (l.rowMonthly, m(s.monthly, s.currency)),
        (l.rowMonths, '${s.months}'),
        (l.rowTotal, m(s.total, s.currency)),
        if (s.cashPrice != null) (l.rowCash, m(s.cashPrice!, s.currency)),
        if (s.extra != null && s.extra! > 0) (l.rowExtra, m(s.extra!, s.currency)),
      ],
    ),
    UnitPriceSolution() => () {
      final unit = _baseUnit(s.dim, l);
      final b = s.items[s.best];
      final same = s.savingPercent < 0.05;
      return SolutionText(same ? l.unitPriceSame : l.unitPriceHeadline(s.best + 1, m(b.perBase, s.currency), unit), [
        for (var i = 0; i < s.items.length; i++)
          (
            '${l.optionN(i + 1)} · ${n(s.items[i].size)} ${s.items[i].unit.symbol}',
            '${m(s.items[i].price, s.currency)} → ${m(s.items[i].perBase, s.currency)}/$unit',
          ),
      ], note: same ? null : l.unitPriceSaving(n(s.savingPercent, 0)));
    }(),
    FuelSolution() => SolutionText(l.fuelHeadline(m(s.cost, s.currency)), [
      (l.rowDistance, '${n(s.km, 0)} km'),
      (l.rowFuel, '${n(s.litres, 1)} L'),
      (l.rowPrice, '${m(s.pricePerLitre, s.currency)}/L'),
    ]),
    YearlySolution() => SolutionText(l.yearlyHeadline(m(s.yearly, s.currency)), [
      (l.rowMonthly, m(s.monthly, s.currency)),
      (l.rowYearly, m(s.yearly, s.currency)),
    ]),
    ConvertSolution() => SolutionText(
      '${n(s.value)} ${s.from.symbol} = ${n(s.result, s.from.dim == Dim.temperature ? 1 : 3)} ${s.to.symbol}',
      const [],
    ),
    CalcSolution() => SolutionText('= ${n(s.value, 6)}', [(s.expression, n(s.value, 6))]),
    DaysUntilSolution() => SolutionText(l.daysUntilHeadline(s.days), [(l.rowDate, fmt.fullDate(s.date))]),
  };
}

String _baseUnit(Dim d, AppLocalizations l) => switch (d) {
  Dim.volume => 'L',
  Dim.mass => 'kg',
  Dim.length => 'm',
  _ => l.unitPieceLabel,
};
