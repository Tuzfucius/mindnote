import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';

/// 导出服务
class ExportService {
  /// 导出为 Markdown
  Future<String> exportToMarkdown(List<Note> notes, {String? title}) async {
    final buffer = StringBuffer();

    // 标题
    buffer.writeln('# ${title ?? 'MindNote 导出'}');
    buffer.writeln('');
    buffer.writeln('> 导出时间: ${DateTime.now().toIso8601String()}');
    buffer.writeln('> 笔记数量: ${notes.length}');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');

    // 分类导出
    final favoriteNotes = notes.where((n) => n.isFavorite).toList();
    final otherNotes = notes.where((n) => !n.isFavorite).toList();

    // 收藏笔记
    if (favoriteNotes.isNotEmpty) {
      buffer.writeln('## ⭐ 收藏笔记');
      buffer.writeln('');
      for (final note in favoriteNotes) {
        _formatNoteAsMarkdown(buffer, note);
      }
      buffer.writeln('');
    }

    // 其他笔记
    if (otherNotes.isNotEmpty) {
      buffer.writeln('## 📝 其他笔记');
      buffer.writeln('');
      for (final note in otherNotes) {
        _formatNoteAsMarkdown(buffer, note);
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  void _formatNoteAsMarkdown(StringBuffer buffer, Note note) {
    buffer.writeln('### ${note.title.isNotEmpty ? note.title : '无标题'}');
    buffer.writeln('');
    
    // 元数据
    buffer.writeln('| 属性 | 值 |');
    buffer.writeln('|------|-----|');
    buffer.writeln('| 创建时间 | ${_formatDate(note.createdAt)} |');
    buffer.writeln('| 更新时间 | ${_formatDate(note.updatedAt)} |');
    if (note.tags.isNotEmpty) {
      buffer.writeln('| 标签 | ${note.tags.join(', ')} |');
    }
    buffer.writeln('');
    
    // 内容
    buffer.writeln(note.content);
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
  }

  /// 导出为单个笔记文件
  Future<String> exportNoteToMarkdown(Note note) async {
    final buffer = StringBuffer();

    buffer.writeln('# ${note.title.isNotEmpty ? note.title : '无标题'}');
    buffer.writeln('');
    buffer.writeln('**标签**: ${note.tags.isNotEmpty ? note.tags.join(', ') : '无'}');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('');
    buffer.writeln(note.content);
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('*创建于: ${_formatDate(note.createdAt)}*');
    buffer.writeln('*更新于: ${_formatDate(note.updatedAt)}*');

    return buffer.toString();
  }

  /// 保存文件
  Future<File> saveToFile(String content, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
    return file;
  }

  /// 分享内容（返回可分享的文本）
  String shareAsText(Note note) {
    final buffer = StringBuffer();
    buffer.writeln(note.title.isNotEmpty ? note.title : '无标题');
    buffer.writeln('');
    buffer.writeln(note.content);
    if (note.tags.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('#${note.tags.join(' #')}');
    }
    return buffer.toString();
  }

  /// 批量导出为多个文件
  Future<List<File>> exportMultipleFiles(
    List<Note> notes, {
    bool favoritesOnly = false,
  }) async {
    final exportNotes = favoritesOnly
        ? notes.where((n) => n.isFavorite).toList()
        : notes;

    final files = <File>[];
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/mindnote-export');
    
    if (!exportDir.existsSync()) {
      exportDir.createSync(recursive: true);
    }

    for (final note in exportNotes) {
      final filename = _sanitizeFilename(
        '${note.title.isNotEmpty ? note.title : 'note-${note.id.substring(0, 8)}'}.md',
      );
      final content = await exportNoteToMarkdown(note);
      final file = File('${exportDir.path}/$filename');
      await file.writeAsString(content);
      files.add(file);
    }

    return files;
  }

  /// 清理文件名
  String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
