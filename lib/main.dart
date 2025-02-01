import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:isar/isar.dart';
import 'package:lote0130/features/home/models/note.dart';
import 'package:lote0130/features/home/note_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/providers/providers.dart';
import 'features/home/home_screen.dart';
import 'core/models/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量
  await dotenv.load();

  // 初始化 Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // 初始化 Isar
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ProfileSchema, NoteSchema],
    directory: dir.path,
  );

  // 检查是否存在本地 profile
  final localProfile =
      await isar.profiles.filter().supabaseIdIsNull().findFirst();
  if (localProfile == null) {
    // 创建一个初始的本地 profile
    await isar.writeTxn(() async {
      await isar.profiles.put(Profile());
    });
  }

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  Future<void> _handleLocalNotes(BuildContext context, WidgetRef ref) async {
    final isar = ref.read(isarProvider);
    final localNotes = await isar.notes.filter().userIdIsNull().findAll();

    if (localNotes.isNotEmpty) {
      // 显示合并对话框
      final shouldMerge = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('发现本地笔记'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('发现 ${localNotes.length} 条未同步的本地笔记，是否要合并到您的账户中？'),
                const SizedBox(height: 12),
                Flexible(
                  child: Material(
                    type: MaterialType.transparency,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final note in localNotes)
                            ListTile(
                              dense: true,
                              title: Text(
                                note.currentContent ?? '空笔记',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '创建于 ${note.createdAt?.toString().substring(0, 16) ?? '未知时间'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('不合并'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('合并'),
            ),
          ],
        ),
      );

      if (shouldMerge == true) {
        final userId = ref.read(authStateProvider).value?.session?.user.id;
        if (userId != null) {
          // 合并笔记
          await isar.writeTxn(() async {
            for (final note in localNotes) {
              note.userId = userId;
              note.isSynced = false; // 标记为需要同步
              await isar.notes.put(note..userId = userId);
            }
          });

          // 先更新UI
          await ref.read(noteProvider.notifier).loadNotes(userId);

          // 后台触发同步
          ref
              .read(noteRepositoryProvider)
              .syncNotes(userId, localNotes)
              .then((_) {
            // 同步完成后再次更新UI显示同步状态
            ref.read(noteProvider.notifier).loadNotes(userId);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '笔记',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff8acf00)),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) {
            final authState = ref.watch(authStateProvider);
            final profileAsync = ref.watch(currentProfileProvider);

            return authState.when(
              data: (state) {
                if (state.session == null) {
                  return const HomeScreen(); // 未登录时直接显示主页，使用本地功能
                }
                return profileAsync.when(
                  data: (profile) {
                    if (profile == null) {
                      return const Center(child: Text('加载用户信息失败'));
                    }
                    // 检查并处理本地笔记
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _handleLocalNotes(context, ref);
                    });
                    return const HomeScreen();
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('profile错误：$error')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('authState错误：$error')),
            );
          },
        ),
      ),
    );
  }
}
