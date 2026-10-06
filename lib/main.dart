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
    for (final f in ['Fraunces', 'PlusJakartaSans']) {
      yield LicenseEntryWithLineBreaks([f], await rootBundle.loadString('assets/fonts/OFL-$f.txt'));
    }
    // On-device model (downloaded on request).
    yield const LicenseEntryWithLineBreaks(
      ['Gemma 3 1B (Lio offline model)'],
      '''
Gemma is provided under and subject to the Gemma Terms of Use found at https://ai.google.dev/gemma/terms
Use is restricted by the Gemma Prohibited Use Policy: https://ai.google.dev/gemma/prohibited_use_policy''',
    );
  });
  final services = await buildServices();
  installErrorHandlers(services.crash);

  final settings = SettingsStore(services.prefs).load();
  await services.analytics.setEnabled(settings.analyticsEnabled);
  await services.crash.setEnabled(settings.crashReportingEnabled);

  runApp(ProviderScope(overrides: [servicesProvider.overrideWithValue(services)], child: const LifeOsApp()));
}
