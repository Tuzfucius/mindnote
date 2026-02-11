import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/llm_service.dart';
import '../services/search_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagController;

  List<String> _tags = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isExpanded = false; // 编辑器展开状态

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _tagController = TextEditingController();
    _tags = note?.tags ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = await Provider.of<Future<DatabaseService>>(context, listen: false).then((f) => f);
      final note = widget.note?.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        tags: _tags,
      ) ?? Note(
        title: _titleController.text,
        content: _contentController.text,
        tags: _tags,
      );

      if (widget.note != null) {
        await db.updateNote(note);
      } else {
        await db.insertNote(note);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _generateInspiration() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入一些内容')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final llmService = Provider.of<LLMService>(context, listen: false);
      final inspiration = await llmService.generateInspiration(
        _contentController.text,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('💡 灵感激发'),
            content: SingleChildScrollView(
              child: Text(inspiration),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              FilledButton(
                onPressed: () {
                  _contentController.text += '\n\n$inspiration';
                  Navigator.pop(context);
                },
                child: const Text('插入'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _suggestTags() async {
    if (_contentController.text.isEmpty && _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入内容')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final llmService = Provider.of<LLMService>(context, listen: false);
      final content = '${_titleController.text}\n${_contentController.text}';
      final suggestions = await llmService.suggestTags(content);

      if (mounted && suggestions.isNotEmpty) {
        setState(() {
          for (final tag in suggestions) {
            if (!_tags.contains(tag)) {
              _tags.add(tag);
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加了 ${suggestions.length} 个标签')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('标签生成失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onWillPop: () async {
        await _saveNote();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? '新建笔记' : '编辑笔记'),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _isLoading ? null : _generateInspiration,
              tooltip: '灵感激发',
            ),
            IconButton(
              icon: const Icon(Icons.tag),
              onPressed: _isLoading ? null : _suggestTags,
              tooltip: '智能标签',
            ),
            IconButton(
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              onPressed: _isSaving ? null : _saveNote,
            ),
          ],
        ),
        body: Column(
          children: [
            // 标题输入
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),

            // 标签
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _tags.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final tag = _tags[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tag,
                                  style: TextStyle(color: Colors.blue[800]),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _removeTag(tag),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: '添加标签',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 24),

            // 内容输入
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: '记录你的灵感...',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            // 底部提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '点击顶部按钮使用 AI 激发灵感',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
