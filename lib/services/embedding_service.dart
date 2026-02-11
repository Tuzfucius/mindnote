import 'dart:math';
import 'dart:typed_data';
import '../models/note.dart';

/// 简单的向量嵌入服务
/// 后期可替换为真实的 Embedding API（如 OpenAI embeddings）
class EmbeddingService {
  // 模拟向量维度
  static const int embeddingDim = 384;

  /// 生成文本的向量表示（简化版：基于 TF-IDF 思想）
  /// 后期替换为真实 embedding: OpenAI / DeepSeek / HuggingFace
  Future<List<double>> generateEmbedding(String text) async {
    // 简单分词
    final words = _tokenize(text.toLowerCase());
    
    // 生成稀疏向量（词 -> 权重）
    final wordWeights = <String, double>{};
    for (final word in words) {
      wordWeights[word] = (wordWeights[word] ?? 0) + 1.0;
    }

    // 归一化
    final total = wordWeights.values.fold(0.0, (a, b) => a + b * b);
    final norm = sqrt(total > 0 ? total : 1.0);
    
    // 转换为固定维度向量（使用确定性随机）
    final vector = List<double>.filled(embeddingDim, 0.0);
    final random = Random(_hashCode(text));
    
    var weightSum = 0.0;
    for (final entry in wordWeights.entries) {
      final hash = _hashCode(entry.key) % embeddingDim;
      final weight = entry.value / norm;
      vector[hash.abs()] = weight;
      weightSum += weight;
    }

    return vector;
  }

  /// 计算两个向量的余弦相似度
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    return denominator > 0 ? dotProduct / denominator : 0.0;
  }

  /// 语义搜索
  Future<List<SearchResult>> semanticSearch({
    required String query,
    required List<Note> notes,
    double threshold = 0.3,
    int topK = 10,
  }) async {
    final queryEmbedding = await generateEmbedding(query);
    final results = <SearchResult>[];

    for (final note in notes) {
      if (note.embedding != null) {
        final noteEmbedding = _decodeEmbedding(note.embedding!);
        final score = cosineSimilarity(queryEmbedding, noteEmbedding);
        
        if (score >= threshold) {
          results.add(SearchResult(note: note, score: score));
        }
      }
    }

    // 排序并返回 topK
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(topK).toList();
  }

  /// 编码向量为字符串
  String _encodeEmbedding(List<double> vector) {
    return vector.map((v) => v.toStringAsFixed(6)).join(',');
  }

  /// 解码字符串为向量
  List<double> _decodeEmbedding(String encoded) {
    return encoded.split(',').map((s) => double.tryParse(s) ?? 0.0).toList();
  }

  /// 简单分词
  List<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 1)
        .toList();
  }

  /// 字符串哈希（确定性）
  int _hashCode(String text) {
    var hash = 0;
    for (var i = 0; i < text.length; i++) {
      hash = ((hash << 5) - hash) + text.codeUnitAt(i);
      hash = hash & hash; // 转换为32位整数
    }
    return hash.abs();
  }
}

/// 向量存储（简化版：存储在 SQLite 中）
class VectorStore {
  final Map<String, List<double>> _vectors = {};

  /// 存储向量
  Future<void> store(String noteId, List<double> embedding) async {
    _vectors[noteId] = embedding;
  }

  /// 获取向量
  List<double>? get(String noteId) => _vectors[noteId];

  /// 删除向量
  Future<void> delete(String noteId) async {
    _vectors.remove(noteId);
  }

  /// 获取所有向量
  Map<String, List<double>> getAll() => Map.from(_vectors);
}
