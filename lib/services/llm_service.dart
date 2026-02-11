import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/note.dart';

/// LLM 服务配置
class LLMConfig {
  final String apiKey;
  final String baseUrl;
  final String model;

  LLMConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.deepseek.com',
    this.model = 'deepseek-chat',
  });

  factory LLMConfig.deepseek(String apiKey) {
    return LLMConfig(
      apiKey: apiKey,
      baseUrl: 'https://api.deepseek.com',
      model: 'deepseek-chat',
    );
  }

  factory LLMConfig.openai(String apiKey) {
    return LLMConfig(
      apiKey: apiKey,
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-3.5-turbo',
    );
  }
}

/// LLM 服务
class LLMService {
  final LLMConfig config;
  final Dio _dio;

  LLMService({required this.config}) : _dio = Dio() {
    _dio.options.headers['Authorization'] = 'Bearer ${config.apiKey}';
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  /// 灵感激发：根据当前笔记内容生成相关联想
  Future<String> generateInspiration(String content, {String? context}) async {
    final prompt = '''
你是一个创意助手。用户正在记录灵感或笔记。

当前内容：
$content

${context != null ? '背景信息：\n$context' : ''}

请基于以上内容，生成 3-5 个相关的灵感联想、扩展思路或问题引导。

要求：
- 简洁直接，不要太长
- 启发性而非回答性
- 用bullet points列出

开始生成：
''';

    return _callLLM(prompt);
  }

  /// 内容补充：帮助完善笔记内容
  Future<String> expandContent(String content, String instruction) async {
    final prompt = '''
用户正在完善笔记内容。

原始内容：
$content

用户要求：$instruction

请基于以上要求，扩展或修改内容，保持笔记的简洁风格。

扩展后的内容：
''';

    return _callLLM(prompt);
  }

  /// 总结笔记：生成摘要
  Future<String> summarizeContent(String content, {int maxLength = 100}) async {
    final prompt = '''
请用简洁的语言总结以下笔记内容（最多 $maxLength 字）：

$content

摘要：
''';

    return _callLLM(prompt);
  }

  /// 生成标签：根据内容自动推荐标签
  Future<List<String>> suggestTags(String content) async {
    final prompt = '''
根据以下笔记内容，推荐 3-5 个相关标签（用逗号分隔）：

$content

标签：
''';

    final response = await _callLLM(prompt);
    return response.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  /// 语义搜索：生成查询向量（简化版）
  Future<String> generateQueryEmbedding(String query) async {
    final prompt = '''
将以下查询转换为简洁的搜索关键词（不超过10个词）：

$query

关键词：
''';

    return _callLLM(prompt);
  }

  /// 调用 LLM API
  Future<String> _callLLM(String prompt) async {
    try {
      final response = await _dio.post(
        '${config.baseUrl}/chat/completions',
        data: {
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        },
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else {
        throw Exception('API 错误: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('LLM 请求失败: ${e.message}');
    }
  }

  /// 测试 API 连接
  Future<bool> testConnection() async {
    try {
      await _callLLM('你好');
      return true;
    } catch (e) {
      return false;
    }
  }
}
