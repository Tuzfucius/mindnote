import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/search_service.dart';
import '../widgets/common_widgets.dart';
import 'note_editor_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _results = [];
  bool _isSearching = false;
  String _searchMode = 'fuzzy'; // fuzzy, title, tag, semantic

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final searchService = Provider.of<SearchService>(context, listen: false);

      switch (_searchMode) {
        case 'title':
          _results = searchService.searchByTitle(query);
          break;
        case 'tag':
          _results = searchService.searchByTag(query);
          break;
        default:
          _results = searchService.fuzzySearch(query);
      }

      if (mounted) {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '搜索笔记...',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() => _results = []);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索模式选择
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    selected: _searchMode == 'fuzzy',
                    label: const Text('智能搜索'),
                    onSelected: (selected) {
                      setState(() => _searchMode = 'fuzzy');
                      _search(_searchController.text);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _searchMode == 'title',
                    label: const Text('标题'),
                    onSelected: (selected) {
                      setState(() => _searchMode = 'title');
                      _search(_searchController.text);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: _searchMode == 'tag',
                    label: const Text('标签'),
                    onSelected: (selected) {
                      setState(() => _searchMode = 'tag');
                      _search(_searchController.text);
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // 搜索结果
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? '输入关键词搜索笔记'
                : '未找到相关笔记',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final note = result.note;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteEditorScreen(note: note),
                ),
              );
              if (shouldRefresh == true) {
                _search(_searchController.text);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: HighlightText(
                          text: note.title.isNotEmpty ? note.title : '无标题',
                          highlight: _searchController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          highlightStyle: const TextStyle(
                            backgroundColor: Colors.yellow,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (note.isFavorite)
                        const Icon(Icons.favorite, color: Colors.red, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  HighlightText(
                    text: note.content.substring(
                      0,
                      min(150, note.content.length),
                    ),
                    highlight: _searchController.text,
                    style: TextStyle(color: Colors.grey[600]),
                    highlightStyle: const TextStyle(
                      backgroundColor: Colors.yellow,
                      color: Colors.black,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(note.updatedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const Spacer(),
                      if (note.tags.isNotEmpty)
                        ...note.tags.take(2).map((tag) => Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: HighlightText(
                                text: tag,
                                highlight: _searchController.text,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                ),
                              ),
                            )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${date.year}/${date.month}/${date.day}';
    }
  }
}
