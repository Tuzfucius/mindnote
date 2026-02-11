import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';

/// 笔记模型
class Note extends Equatable {
  final String id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final String? embedding; // 语义向量（后期）

  const Note({
    String? id,
    required this.title,
    required this.content,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isFavorite = false,
    this.embedding,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 创建空笔记
  static Note empty() {
    return Note(
      title: '',
      content: '',
      tags: [],
    );
  }

  /// 是否为空笔记
  bool get isEmpty => title.isEmpty && content.isEmpty;

  /// 转为 Map（存入数据库）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'embedding': embedding,
    };
  }

  /// 从 Map 读取
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      tags: (map['tags'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isFavorite: (map['is_favorite'] as int) == 1,
      embedding: map['embedding'] as String?,
    );
  }

  /// 复制并修改
  Note copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    String? embedding,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      embedding: embedding ?? this.embedding,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        tags,
        createdAt,
        updatedAt,
        isFavorite,
        embedding,
      ];

  @override
  String toString() {
    return 'Note(id: $id, title: $title, content: ${content.substring(0, min(50, content.length))}...)';
  }
}

/// 搜索结果
class SearchResult {
  final Note note;
  final double score; // 相似度分数

  SearchResult({required this.note, required this.score});
}

/// 笔记统计
class NoteStats {
  final int totalNotes;
  final int favoriteNotes;
  final int totalTags;
  final DateTime? lastUpdated;

  NoteStats({
    required this.totalNotes,
    required this.favoriteNotes,
    required this.totalTags,
    this.lastUpdated,
  });
}
