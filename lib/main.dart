import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/llm_service.dart';
import 'services/search_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MindNoteApp());
}

class MindNoteApp extends StatelessWidget {
  const MindNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 数据库服务
        FutureProvider<DatabaseService>(
          create: (_) async {
            final db = DatabaseService();
            await db.init();
            return db;
          },
        ),
        // 搜索服务（依赖数据库）
        ProxyProvider<DatabaseService, SearchService>(
          update: (_, db, __) => SearchService(db: db),
        ),
        // LLM 服务（需要配置）
        ChangeNotifierProvider<LLMService>(
          create: (_) => LLMService(
            config: LLMConfig.deepseek('YOUR_API_KEY'), // TODO: 从配置读取
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MindNote',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
