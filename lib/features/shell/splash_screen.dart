import 'package:flutter/material.dart';

import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.blur_circular_rounded, size: 56, color: context.colors.primary),
          const SizedBox(height: Space.md),
          Text(context.l10n.appName, style: context.text.headlineSmall),
        ],
      ),
    ),
  );
}
