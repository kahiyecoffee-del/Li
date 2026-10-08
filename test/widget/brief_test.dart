import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/features/news/morning_brief.dart';
import 'package:lifeos/services/news/news_service.dart';

import 'harness.dart';

NewsArticle art(String id, String topic, String title, {int hoursAgo = 1}) => NewsArticle(
  id: id,
  title: title,
  source: 'Wire',
  url: 'https://example.com/$id',
  topic: topic,
  description: 'One line about $title.',
  publishedAt: DateTime.now().subtract(Duration(hours: hoursAgo)),
);

final _news = [
  art('w1', 'world', 'Leaders meet in Geneva'),
  art('w2', 'world', 'Storm moves north', hoursAgo: 3),
  art('w3', 'world', 'Old story', hoursAgo: 20),
  art('w4', 'world', 'Older story', hoursAgo: 30),
  art('t1', 'technology', 'New phone announced'),
  art('t2', 'technology', 'Leaders meet in Geneva', hoursAgo: 2), // same story twice
];

void main() {
  test('digest: per topic, newest first, no repeats, in the user’s order', () {
    final d = morningDigest(_news, ['technology', 'world']);
    expect(d.map((s) => s.topic), ['technology', 'world']);
    expect(d.first.articles.map((a) => a.id), ['t1', 't2']);
    expect(d.last.articles.map((a) => a.id), ['w2', 'w3']);
    expect(briefSeconds(d), inInclusiveRange(10, 120));
    expect(morningDigest(_news, ['sports']), isEmpty);
  });

  testWidgets('Home shows the brief; opening it marks today read', (tester) async {
    usePhoneViewport(tester);
    final app = (await tester.runAsync(() => TestApp.onboarded(news: _news)))!;
    await tester.pumpWidget(app.widget());
    await pumpUntil(tester, find.text('What should we solve today?'));
    unawaited(GoRouter.of(tester.element(find.text('What should we solve today?'))).push('/brief'));
    await pumpUntil(tester, find.text('Leaders meet in Geneva'));
    expect(find.text('Storm moves north'), findsOneWidget);
    expect(find.text('Leaders meet in Geneva'), findsOneWidget); // no repeats
    expect(find.text('Older story'), findsNothing); // two per topic
    expect(find.byKey(const Key('brief-day')), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Sports'));
    await tester.pump(const Duration(milliseconds: 300));
    final profile = (await tester.runAsync(() => app.seededRepos.profile.getAll()))!.single;
    expect(profile.newsTopics, contains('sports'));
    await tester.pageBack();
    await pumpUntil(tester, find.byKey(const Key('morning-brief')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('up to date'), findsOneWidget);
    await tearDownApp(tester);
  });
}
