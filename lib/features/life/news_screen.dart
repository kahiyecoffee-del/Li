import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../premium/native_slot.dart';
import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/json.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../services/ai/ai_models.dart';
import '../../services/news/news_service.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final news = ref.watch(newsProvider(lang));
    final profile = ref.watch(profileProvider).value;
    final topics = profile?.newsTopics ?? const ['world'];
    return Scaffold(
      appBar: AppBar(title: Text(l.lifeNews)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(newsProvider(lang).future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.page, Space.sm, Space.page, Space.xxl),
          children: [
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: newsTopics
                  .map(
                    (t) => FilterChip(
                      label: Text(l.newsTopic(t)),
                      selected: topics.contains(t),
                      onSelected: (v) {
                        final next = {...topics};
                        v ? next.add(t) : next.remove(t);
                        if (next.isEmpty || profile == null) return;
                        ref.read(actionsProvider).saveProfile(profile.copyWith(newsTopics: next.toList()));
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Space.md),
            ...news.when(
              loading: () => [const Padding(padding: EdgeInsets.all(Space.xxl), child: LoadingView())],
              error: (e, _) => [ErrorView(error: e, onRetry: () => ref.invalidate(newsProvider(lang)))],
              data: (list) => list.isEmpty
                  ? [EmptyState(icon: Icons.newspaper_outlined, message: l.newsUnavailable)]
                  : [
                      for (final (i, a) in list.indexed) ...[
                        _ArticleCard(article: a),
                        if (NativeSlot.after(ref, i)) const NativeSlot(),
                      ],
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends ConsumerWidget {
  const _ArticleCard({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final fmt = ref.fmt(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: AppCard(
        onTap: () => launchUrl(Uri.parse(article.url), mode: LaunchMode.externalApplication),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [article.source, if (article.publishedAt != null) fmt.dayMonth(article.publishedAt!)].join(' · '),
              style: context.text.labelSmall?.copyWith(color: context.semantic.muted),
            ),
            const SizedBox(height: Space.xs),
            Text(article.title, style: context.text.titleMedium),
            if (article.description.isNotEmpty) ...[
              const SizedBox(height: Space.xs),
              Text(article.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _whyItMatters(context, ref),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(l.newsWhyMatters),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _whyItMatters(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final future = ref.read(servicesProvider).ai.task(AiTaskType.newsWhy, {
      'title': article.title,
      'description': article.description,
      'source': article.source,
      'locale': Localizations.localeOf(context).languageCode,
      'focusAreas': ref.read(profileProvider).value?.focusAreas.map((f) => f.name).toList() ?? const <String>[],
    });
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
        child: FutureBuilder<AiTaskResponse>(
          future: future,
          builder: (c, snap) {
            if (snap.connectionState != ConnectionState.done) return const SizedBox(height: 160, child: LoadingView());
            if (snap.hasError) return ErrorView(error: snap.error);
            ref.read(creditsProvider.notifier).set(snap.data!.credits);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.newsWhyMatters, style: c.text.titleLarge),
                const SizedBox(height: Space.md),
                Text(J.str(snap.data!.result, 'text'), style: c.text.bodyLarge),
              ],
            );
          },
        ),
      ),
    );
  }
}
