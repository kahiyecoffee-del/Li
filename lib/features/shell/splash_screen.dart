import 'package:flutter/material.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/mascot.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Mascot(mood: MascotMood.front, size: 120, float: false),
          const SizedBox(height: Space.md),
          Text(context.l10n.appName, style: context.text.headlineSmall),
        ],
      ),
    ),
  );
}
