import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_failure.dart';
import '../../core/utils/json.dart';

const newsTopics = ['nation', 'world', 'finance', 'technology', 'sports', 'science', 'health', 'entertainment'];

class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.source,
    required this.url,
    required this.topic,
    this.description = '',
    this.publishedAt,
    this.imageUrl,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> j) => NewsArticle(
    id: J.str(j, 'id'),
    title: J.str(j, 'title'),
    source: J.str(j, 'source'),
    url: J.str(j, 'url'),
    topic: J.str(j, 'topic'),
    description: J.str(j, 'description'),
    publishedAt: J.date(j, 'publishedAt'),
    imageUrl: J.strOrNull(j, 'imageUrl'),
  );

  final String id;
  final String title;
  final String source;
  final String url;
  final String topic;
  final String description;
  final DateTime? publishedAt;
  final String? imageUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'source': source,
    'url': url,
    'topic': topic,
    'description': description,
    if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
    if (imageUrl != null) 'imageUrl': imageUrl,
  };
}

/// News provider abstraction. The production implementation calls the
/// `getNews` Cloud Function, which holds the news API key and can switch
/// providers (GNews / NewsAPI / …) server-side.
abstract class NewsProvider {
  Future<List<NewsArticle>> headlines({required List<String> topics, required String language, String? country});
}

class BackendNewsProvider implements NewsProvider {
  BackendNewsProvider(this._functions);

  final FirebaseFunctions _functions;

  @override
  Future<List<NewsArticle>> headlines({required List<String> topics, required String language, String? country}) async {
    try {
      final res = await _functions.httpsCallable('getNews').call<Object?>({
        'topics': topics,
        'language': language,
        'country': ?country,
      });
      final d = res.data;
      if (d is! Map) return const [];
      return J.mapList(d.cast<String, dynamic>(), 'articles').map(NewsArticle.fromJson).toList();
    } on FirebaseFunctionsException catch (e) {
      throw AppFailure(FailureKind.unavailable, cause: e);
    }
  }
}

class UnavailableNewsProvider implements NewsProvider {
  @override
  Future<List<NewsArticle>> headlines({
    required List<String> topics,
    required String language,
    String? country,
  }) async => throw const AppFailure(FailureKind.unavailable);
}

/// One-hour cache per topic set and language.
class NewsService {
  NewsService(this._provider, this._prefs);

  final NewsProvider _provider;
  final SharedPreferences _prefs;
  static const ttl = Duration(hours: 1);

  Future<List<NewsArticle>> headlines(List<String> topics, String language, {bool force = false}) async {
    final key = 'news_${language}_${(topics.toList()..sort()).join(',')}';
    final raw = _prefs.getString(key);
    List<NewsArticle>? cached;
    if (raw != null) {
      try {
        final j = (jsonDecode(raw) as Map).cast<String, dynamic>();
        cached = J.mapList(j, 'a').map(NewsArticle.fromJson).toList();
        final at = J.date(j, 'at');
        if (!force && at != null && DateTime.now().difference(at) < ttl) return cached;
      } catch (_) {}
    }
    try {
      final fresh = await _provider.headlines(topics: topics, language: language);
      await _prefs.setString(
        key,
        jsonEncode({'at': DateTime.now().millisecondsSinceEpoch, 'a': fresh.map((a) => a.toJson()).toList()}),
      );
      return fresh;
    } catch (e) {
      if (cached != null) return cached;
      rethrow;
    }
  }
}

/// Scripted headlines for tests and previews.
class FakeNewsProvider implements NewsProvider {
  const FakeNewsProvider(this.articles);
  final List<NewsArticle> articles;

  @override
  Future<List<NewsArticle>> headlines({
    required List<String> topics,
    required String language,
    String? country,
  }) async => articles.where((a) => topics.contains(a.topic)).toList();
}
