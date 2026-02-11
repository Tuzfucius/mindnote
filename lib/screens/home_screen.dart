import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../services/search_service.dart';
import 'note_editor_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    try {
      final db = await Provider.of<Future<DatabaseService>>(context).then((f) => f);
      final searchService = Provider.of<SearchService>(context);
      final results = searchService.getRecentNotes(limit: 50);
      
      if (mounted) {
        setState(() {
          _notes = results.map((r) => r.note).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MindNote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _navigateToSearch(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(),
        icon: const Icon(Icons.add),
        label: const Text('新笔记'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有笔记',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮创建第一个灵感',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _navigateToEditor(),
            icon: const Icon(Icons.add),
            label: const Text('创建笔记'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            onTap: () => _navigateToEditor(note: note),
            title: Text(
              note.title.isNotEmpty ? note.title : '无标题',
              style: TextStyle(
                fontWeight: note.title.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  note.content.substring(0, min(100, note.content.length)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (note.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: note.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[800],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            trailing: Icon(
              note.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: note.isFavorite ? Colors.red : null,
            ),
            isThreeLine: note.tags.isNotEmpty,
          ),
        );
      },
    );
  }

  void _navigateToEditor({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(note: note),
      ),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  void _navigateToSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );

    if (result == true) {
      _loadNotes();
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.api),
              title: const Text('API 配置'),
              subtitle: const Text('设置 LLM API Key'),
              onTap: () => _showApiConfig(),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('关于'),
              subtitle: const Text('MindNote v0.1.0'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _showApiConfig() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 配置'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: '输入你的 DeepSeek API Key',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              // TODO: 保存 API Key
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API Key 已保存')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
