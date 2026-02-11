import 'dart:async';
import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import '../models/note.dart';

/// 本地数据库服务
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  final _dbPath = 'mindnote.db';

  /// 初始化数据库
  Future<void> init() async {
    if (_database != null) return;

    // 确保目录存在
    final dbFile = File(_dbPath);
    await dbFile.parent.create(recursive: true);

    _database = sqlite3.open(_dbPath);
    _createTables();

    print('✅ 数据库初始化成功: $_dbPath');
  }

  /// 创建表
  void _createTables() {
    _database!.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_favorite INTEGER DEFAULT 0,
        embedding TEXT
      )
    ''');

    _database!.execute('''
      CREATE TABLE IF NOT EXISTS tags (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE,
        usage_count INTEGER DEFAULT 0
      )
    ''');

    // 创建全文搜索索引
    _database!.execute('''
      CREATE INDEX IF NOT EXISTS idx_notes_title ON notes(title);
      CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(updated_at);
      CREATE INDEX IF NOT EXISTS idx_notes_favorite ON notes(is_favorite);
    ''');
  }

  /// 插入笔记
  Future<Note> insertNote(Note note) async {
    final stmt = _database!.prepare(
      'INSERT OR REPLACE INTO notes (id, title, content, tags, created_at, updated_at, is_favorite, embedding) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    );
    stmt.execute([
      note.id,
      note.title,
      note.content,
      note.tags.join(','),
      note.createdAt.toIso8601String(),
      note.updatedAt.toIso8601String(),
      note.isFavorite ? 1 : 0,
      note.embedding,
    ]);
    stmt.dispose();
    return note;
  }

  /// 更新笔记
  Future<Note> updateNote(Note note) async {
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    final stmt = _database!.prepare(
      'UPDATE notes SET title = ?, content = ?, tags = ?, updated_at = ?, is_favorite = ?, embedding = ? WHERE id = ?'
    );
    stmt.execute([
      updatedNote.title,
      updatedNote.content,
      updatedNote.tags.join(','),
      updatedNote.updatedAt.toIso8601String(),
      updatedNote.isFavorite ? 1 : 0,
      updatedNote.embedding,
      updatedNote.id,
    ]);
    stmt.dispose();
    return updatedNote;
  }

  /// 删除笔记
  Future<void> deleteNote(String id) async {
    final stmt = _database!.prepare('DELETE FROM notes WHERE id = ?');
    stmt.execute([id]);
    stmt.dispose();
  }

  /// 获取单个笔记
  Note? getNote(String id) {
    final result = _database!.select(
      'SELECT * FROM notes WHERE id = ?',
      [id],
    );
    if (result.isEmpty) return null;
    return Note.fromMap(result.first);
  }

  /// 获取所有笔记（按更新时间倒序）
  List<Note> getAllNotes({int limit = 100, int offset = 0}) {
    final result = _database!.select(
      'SELECT * FROM notes ORDER BY updated_at DESC LIMIT ? OFFSET ?',
      [limit, offset],
    );
    return result.map((row) => Note.fromMap(row)).toList();
  }

  /// 搜索笔记（LIKE 查询）
  List<Note> searchNotes(String query, {int limit = 50}) {
    final searchPattern = '%$query%';
    final result = _database!.select(
      '''SELECT * FROM notes 
         WHERE title LIKE ? OR content LIKE ? OR tags LIKE ? 
         ORDER BY updated_at DESC LIMIT ?''',
      [searchPattern, searchPattern, searchPattern, limit],
    );
    return result.map((row) => Note.fromMap(row)).toList();
  }

  /// 获取收藏笔记
  List<Note> getFavoriteNotes({int limit = 50}) {
    final result = _database!.select(
      'SELECT * FROM notes WHERE is_favorite = 1 ORDER BY updated_at DESC LIMIT ?',
      [limit],
    );
    return result.map((row) => Note.fromMap(row)).toList();
  }

  /// 获取笔记统计
  NoteStats getStats() {
    final totalResult = _database!.select('SELECT COUNT(*) as count FROM notes');
    final total = totalResult.first['count'] as int;

    final favoriteResult = _database!.select('SELECT COUNT(*) as count FROM notes WHERE is_favorite = 1');
    final favorites = favoriteResult.first['count'] as int;

    final tagResult = _database!.select('SELECT DISTINCT tags FROM notes');
    final allTags = <String>{};
    for (final row in tagResult) {
      final tags = (row['tags'] as String?)?.split(',') ?? [];
      allTags.addAll(tags);
    }

    final lastUpdatedResult = _database!.select('SELECT MAX(updated_at) as last FROM notes');
    final lastUpdated = lastUpdatedResult.first['last'] != null
        ? DateTime.tryParse(lastUpdatedResult.first['last'] as String)
        : null;

    return NoteStats(
      totalNotes: total,
      favoriteNotes: favorites,
      totalTags: allTags.length,
      lastUpdated: lastUpdated,
    );
  }

  /// 关闭数据库
  Future<void> close() async {
    _database?.dispose();
    _database = null;
  }
}
