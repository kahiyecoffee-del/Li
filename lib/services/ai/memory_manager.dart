import '../../core/utils/ids.dart';
import '../../data/repositories/repository.dart';
import '../../domain/models/ai_models.dart';
import '../../domain/models/enums.dart';

enum MemorySaveResult { saved, duplicate, limitReached, disabled }

/// User-visible, user-deletable assistant memory.
class MemoryManager {
  MemoryManager(this._repo, {required this.limit, required this.enabled, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Repository<AiMemory> _repo;

  /// Max memories (free tier); `null` = unlimited (Premium).
  final int? limit;
  final bool enabled;
  final DateTime Function() _clock;

  Future<List<AiMemory>> all() async => (await _repo.getAll())..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<(MemorySaveResult, AiMemory?)> save(MemoryCategory category, String content) async {
    if (!enabled) return (MemorySaveResult.disabled, null);
    final text = content.trim();
    final existing = await all();
    final norm = text.toLowerCase();
    if (existing.any((m) => m.content.toLowerCase() == norm)) return (MemorySaveResult.duplicate, null);
    if (limit != null && existing.length >= limit!) return (MemorySaveResult.limitReached, null);
    final m = AiMemory(id: newId(), updatedAt: _clock(), category: category, content: text, createdAt: _clock());
    await _repo.save(m);
    return (MemorySaveResult.saved, m);
  }

  Future<void> delete(String id) => _repo.delete(id);

  Future<void> deleteAll() => _repo.deleteAll();

  /// Memories sent with a chat request (newest first, bounded for cost).
  Future<List<Map<String, String>>> forPrompt({int max = 30}) async => enabled
      ? (await all()).take(max).map((m) => {'category': m.category.name, 'content': m.content}).toList()
      : const [];

  /// Grouped view for "What do you know about me?".
  static Map<MemoryCategory, List<AiMemory>> grouped(List<AiMemory> list) {
    final out = <MemoryCategory, List<AiMemory>>{};
    for (final m in list) {
      out.putIfAbsent(m.category, () => []).add(m);
    }
    return out;
  }
}
