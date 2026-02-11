import '../models/note.dart';
import 'database_service.dart';

/// 搜索服务
class SearchService {
  final DatabaseService _db;

  SearchService({required DatabaseService db}) : _db = db;

  /// 全文搜索
  List<SearchResult> search(String query, {int limit = 20}) {
    if (query.trim().isEmpty) return [];

    final notes = _db.searchNotes(query, limit: limit);

    // 计算简单相关性分数
    final results = notes.map((note) {
      double score = 0.0;

      // 标题匹配分数更高
      if (note.title.toLowerCase().contains(query.toLowerCase())) {
        score += 10.0;
      }

      // 内容匹配
      if (note.content.toLowerCase().contains(query.toLowerCase())) {
        score += 5.0;
      }

      // 标签匹配
      for (final tag in note.tags) {
        if (tag.toLowerCase().contains(query.toLowerCase())) {
          score += 3.0;
          break;
        }
      }

      // 更新时间越近分数越高
      final hoursAgo = DateTime.now().difference(note.updatedAt).inHours;
      if (hoursAgo < 24) {
        score += 2.0;
      } else if (hoursAgo < 168) { // 一周内
        score += 1.0;
      }

      return SearchResult(note: note, score: score);
    }).toList();

    // 按分数排序
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }

  /// 搜索标题
  List<SearchResult> searchByTitle(String query, {int limit = 20}) {
    if (query.trim().isEmpty) return [];

    final allNotes = _db.getAllNotes(limit: 100);
    final filtered = allNotes
        .where((note) => note.title.toLowerCase().contains(query.toLowerCase()))
        .take(limit)
        .map((note) => SearchResult(note: note, score: 10.0))
        .toList();

    return filtered;
  }

  /// 搜索标签
  List<SearchResult> searchByTag(String tag, {int limit = 20}) {
    final allNotes = _db.getAllNotes(limit: 100);
    final filtered = allNotes
        .where((note) => note.tags.any((t) => t.toLowerCase().contains(tag.toLowerCase())))
        .take(limit)
        .map((note) => SearchResult(note: note, score: 8.0))
        .toList();

    return filtered;
  }

  /// 获取最近笔记
  List<SearchResult> getRecentNotes({int limit = 10}) {
    final notes = _db.getAllNotes(limit: limit);
    return notes.map((note) => SearchResult(note: note, score: 0.0)).toList();
  }

  /// 获取收藏笔记
  List<SearchResult> getFavorites({int limit = 20}) {
    final notes = _db.getFavoriteNotes(limit: limit);
    return notes.map((note) => SearchResult(note: note, score: 5.0)).toList();
  }

  /// 模糊搜索（更宽松的匹配）
  List<SearchResult> fuzzySearch(String query, {int limit = 20}) {
    if (query.trim().isEmpty) return [];

    final keywords = query.toLowerCase().split(' ').where((e) => e.isNotEmpty).toList();
    final allNotes = _db.getAllNotes(limit: 100);

    final results = <SearchResult>[];

    for (final note in allNotes) {
      double score = 0.0;
      final titleLower = note.title.toLowerCase();
      final contentLower = note.content.toLowerCase();
      final tagsLower = note.tags.map((t) => t.toLowerCase()).join(' ');

      for (final keyword in keywords) {
        if (titleLower.contains(keyword)) {
          score += 10.0;
        } else if (contentLower.contains(keyword)) {
          score += 5.0;
        } else if (tagsLower.contains(keyword)) {
          score += 3.0;
        }
      }

      if (score > 0) {
        results.add(SearchResult(note: note, score: score));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }
}
