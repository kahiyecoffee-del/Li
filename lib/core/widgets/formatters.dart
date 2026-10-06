import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../utils/money.dart';

/// Locale-aware formatters bound to the user's currency.
class Fmt {
  Fmt(this.locale, this.currency) : _money = MoneyFormatter(locale);

  final String locale;
  final String currency;
  final MoneyFormatter _money;

  String money(int minor, {bool cents = false}) => _money.format(minor, currency, showCents: cents);
  String compactMoney(int minor) => _money.compact(minor, currency);
  String time(DateTime d) => DateFormat.Hm(locale).format(d);
  String dayMonth(DateTime d) => DateFormat.MMMd(locale).format(d);
  String weekdayDayMonth(DateTime d) => DateFormat.MMMEd(locale).format(d);
  String monthYear(DateTime d) => DateFormat.yMMMM(locale).format(d);
  String fullDate(DateTime d) => DateFormat.yMMMd(locale).format(d);
  String dateTime(DateTime d) => '${DateFormat.MMMEd(locale).format(d)} ${DateFormat.Hm(locale).format(d)}';
}

final fmtProvider = Provider.family<Fmt, String>((ref, locale) {
  final currency = ref.watch(profileProvider.select((p) => p.value?.currency ?? 'USD'));
  return Fmt(locale, currency);
});

extension FmtX on WidgetRef {
  Fmt fmt(BuildContext context) => watch(fmtProvider(Localizations.localeOf(context).toLanguageTag()));
}
