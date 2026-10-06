import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';

enum LegalDoc { privacy, terms }

/// Placeholder legal screen. Set PRIVACY_POLICY_URL / TERMS_URL at build time
/// to link the published documents (required before Play release).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.doc});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final url = doc == LegalDoc.privacy ? AppConfig.privacyPolicyUrl : AppConfig.termsUrl;
    return Scaffold(
      appBar: AppBar(title: Text(doc == LegalDoc.privacy ? l.privacyPolicy : l.termsOfService)),
      body: ListView(
        padding: const EdgeInsets.all(Space.page),
        children: [
          if (url.isNotEmpty)
            FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.learnMore),
            )
          else
            Text(l.placeholderLegal, style: context.text.bodyLarge),
          if (doc == LegalDoc.privacy) ...[
            const SizedBox(height: Space.xl),
            Text(l.aiDataTitle, style: context.text.titleMedium),
            const SizedBox(height: Space.sm),
            Text(l.aiDataBody),
            const SizedBox(height: Space.lg),
            Text(l.journalPrivacy),
            const SizedBox(height: Space.lg),
            Text(l.moodDisclaimer),
          ],
        ],
      ),
    );
  }
}
