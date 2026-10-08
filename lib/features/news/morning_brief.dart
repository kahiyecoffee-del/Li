import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/actions.dart';
import '../../app/derived_providers.dart';
import '../../app/providers.dart';
import '../../core/l10n/labels.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/formatters.dart';
import '../../services/news/news_service.dart';
import '../premium/native_slot.dart';

/// Headlines of one topic in the brief.
class BriefSection {
  const BriefSection(this.topic, this.articles);
  final String topic;
  final List<NewsArticle> articles;
}

/// The 30-second brief: up to [perTopic] fresh headlines per chosen topic,
/// in the user's topic order, duplicates (same story in two topics) removed.
List<BriefSection> morningDigest(List<NewsArticle> all, List<String> topics, {int perTopic = 2, int maxTotal = 10}) {
  final seen = <String>{};
  String norm(String t) => t.toLowerCase().replaceAll(RegExp(r'[^a-z0-9çğıöşü]+'), '');
  final out = <BriefSection>[];
  var total = 0;
  for (final topic in topics) {
    final picked = <NewsArticle>[];
    final list = all.where((a) => a.topic == topic).toList()
      ..sort((a, b) => (b.publishedAt ?? DateTime(2000)).compareTo(a.publishedAt ?? DateTime(2000)));
    for (final a in list) {
      if (picked.length >= perTopic || total >= maxTotal) break;
      if (!seen.add(norm(a.title))) continue;
      picked.add(a);
      total++;
    }
    if (picked.isNotEmpty) out.add(BriefSection(topic, picked));
  }
  return out;
}

/// About how long the brief takes to skim (titles + one-line summaries).
int briefSeconds(List<BriefSection> sections) {
  var words = 0;
  for (final s in sections) {
    for (final a in s.articles) {
      words += a.title.split(RegExp(r'\s+')).length + (a.description.split(RegExp(r'\s+')).length ~/ 2);
    }
  }
  // Skimming speed (~5 words a second), rounded to 10 s.
  return ((words / 5) / 10).ceil().clamp(1, 12) * 10;
}

final briefProvider = Provider.family<AsyncValue<List<BriefSection>>, String>((ref, lang) {
  final topics = ref.watch(profileProvider.select((p) => p.value?.newsTopics ?? const ['world']));
  return ref.watch(newsProvider(lang)).whenData((a) => morningDigest(a, topics));
});

/// Whether today's brief was opened (on device).
class BriefReadController extends Notifier<bool> {
  static const _key = 'brief_read';

  @override
  bool build() => ref.watch(servicesProvider).prefs.getString(_key) == Dates.dayKey(ref.watch(todayProvider));

  Future<void> markRead() async {
    if (state) return;
    await ref.read(servicesProvider).prefs.setString(_key, Dates.dayKey(ref.read(todayProvider)));
    state = true;
  }
}

final briefReadProvider = NotifierProvider<BriefReadController, bool>(BriefReadController.new);

/// Morning hub: the day in one line, then the news in 30 seconds.
class MorningBriefScreen extends ConsumerStatefulWidget {
  const MorningBriefScreen({super.key});

  @override
  ConsumerState<MorningBriefScreen> createState() => _MorningBriefScreenState();
}

class _MorningBriefScreenState extends ConsumerState<MorningBriefScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(briefReadProvider.notifier).markRead());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final brief = ref.watch(briefProvider(lang));
    final profile = ref.watch(profileProvider).value;
    final topics = profile?.newsTopics ?? const ['world'];
    final now = ref.watch(clockProvider)();
    final name = (profile?.name ?? '').trim().split(' ').first;
    final today = ref.watch(todayProvider);
    final open =
        ref
            .watch(tasksProvider)
            .list
            .where((t) => !t.deleted && !t.isCompleted && t.anchorDate != null && Dates.sameDay(t.anchorDate!, today))
            .toList()
          ..sort((a, b) => (a.scheduledAt ?? today).compareTo(b.scheduledAt ?? today));
    final first = open.where((t) => t.scheduledAt != null).firstOrNull ?? open.firstOrNull;
    final fmt = ref.fmt(context);
    return Scaffold(
      appBar: AppBar(title: Text(now.hour < 12 ? l.briefMorning : l.briefDay)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(newsProvider(lang).future),
        child: PageList(
          animate: false,
          children: [
            Text(
              name.isEmpty
                  ? (now.hour < 12 ? l.briefMorning : l.briefDay)
                  : (now.hour < 12 ? l.briefHello(name) : l.briefHelloDay(name)),
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: Space.sm),
            AppCard(
              key: const Key('brief-day'),
              onTap: () => context.push('/plan'),
              child: Row(
                children: [
                  const IconBubble(icon: Icons.event_available_rounded, accent: Accent.plan),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.briefDayLine(open.length), style: context.text.titleMedium),
                        if (first != null)
                          Text(
                            l.briefFirst(
                              first.scheduledAt == null
                                  ? first.title
                                  : '${fmt.time(first.scheduledAt!)} ${first.title}',
                            ),
                            style: context.text.bodySmall?.copyWith(color: context.semantic.muted),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: Space.lg),
            ...brief.when(
              loading: () => [const Padding(padding: EdgeInsets.all(Space.xxl), child: LoadingView())],
              error: (_, _) => [EmptyState(icon: Icons.newspaper_outlined, message: l.briefNoNews)],
              data: (sections) => sections.isEmpty
                  ? [EmptyState(icon: Icons.newspaper_outlined, message: l.briefNoNews)]
                  : [
                      Text(
                        l.briefSubtitle(sections.fold(0, (n, s) => n + s.articles.length), briefSeconds(sections)),
                        style: context.text.labelMedium?.copyWith(color: context.semantic.muted),
                      ),
                      const SizedBox(height: Space.sm),
                      for (final (i, s) in sections.indexed) ...[
                        Eyebrow(l.newsTopic(s.topic)),
                        const SizedBox(height: Space.xs),
                        for (final a in s.articles) _Headline(article: a),
                        const SizedBox(height: Space.md),
                        if (i == 1 && NativeSlotEvery.first(ref) >= 0) ...[
                          const NativeSlot(),
                          const SizedBox(height: Space.md),
                        ],
                      ],
                    ],
            ),
            const SizedBox(height: Space.md),
            SectionTitle(l.briefTopics),
            Wrap(
              spacing: Space.sm,
              runSpacing: Space.sm,
              children: [
                for (final t in newsTopics)
                  FilterChip(
                    label: Text(l.newsTopic(t)),
                    selected: topics.contains(t),
                    onSelected: (v) {
                      final next = [...topics.where((x) => x != t), if (v) t];
                      if (next.isEmpty || profile == null) return;
                      ref.read(actionsProvider).saveProfile(profile.copyWith(newsTopics: next));
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Where the brief's single ad may go: only when native ads are on.
abstract final class NativeSlotEvery {
  /// The list index whose [NativeSlot.after] is true first (or -1: none).
  static int first(WidgetRef ref) {
    for (var i = 0; i < 30; i++) {
      if (NativeSlot.after(ref, i)) return i;
    }
    return -1;
  }
}

class _Headline extends ConsumerWidget {
  const _Headline({required this.article});
  final NewsArticle article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = ref.fmt(context);
    final at = article.publishedAt;
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.md),
      onTap: () => launchUrl(Uri.parse(article.url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.title, style: context.text.titleMedium),
            if (article.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  article.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ),
            const SizedBox(height: 2),
            Text(
              [article.source, if (at != null) fmt.time(at.toLocal())].where((s) => s.isNotEmpty).join(' · '),
              style: context.text.labelSmall?.copyWith(color: context.semantic.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home: the brief at a glance (hidden when there is no news).
class MorningBriefCard extends ConsumerWidget {
  const MorningBriefCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final sections = ref.watch(briefProvider(lang)).value;
    if (sections == null || sections.isEmpty) return const SizedBox.shrink();
    final read = ref.watch(briefReadProvider);
    final now = ref.watch(clockProvider)();
    final top = [for (final s in sections) s.articles.first].take(3).toList();
    return Padding(
      padding: const EdgeInsets.only(top: Space.md),
      child: AppCard(
        key: const Key('morning-brief'),
        onTap: () => context.push('/brief'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardHeader(
              icon: Icons.newspaper_rounded,
              title: now.hour < 12 ? l.briefMorning : l.briefDay,
              accent: Accent.news,
            ),
            const SizedBox(height: Space.xs),
            Text(
              read
                  ? l.briefDone
                  : l.briefSubtitle(sections.fold(0, (n, s) => n + s.articles.length), briefSeconds(sections)),
              style: context.text.labelMedium?.copyWith(color: context.semantic.muted),
            ),
            const SizedBox(height: Space.sm),
            for (final a in top)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: Text(
                  '• ${a.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium,
                ),
              ),
            if (!read)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => context.push('/brief'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(l.briefRead),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
