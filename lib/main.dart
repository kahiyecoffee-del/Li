import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'bootstrap.dart';
import 'services/settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Nunito'], text);
  });
  final services = await buildServices();
  installErrorHandlers(services.crash);

  final settings = SettingsStore(services.prefs).load();
  await services.analytics.setEnabled(settings.analyticsEnabled);
  await services.crash.setEnabled(settings.crashReportingEnabled);

  runApp(ProviderScope(overrides: [servicesProvider.overrideWithValue(services)], child: const LifeOsApp()));
}
