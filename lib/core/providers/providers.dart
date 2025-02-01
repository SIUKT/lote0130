import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/auth_repository.dart';
import '../models/profile.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(isarProvider),
    ref.watch(supabaseClientProvider),
  );
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentProfileProvider = FutureProvider.autoDispose<Profile?>((ref) {
  // 监听 auth 状态变化
  final authState = ref.watch(authStateProvider);
  
  // 当 auth 状态发生变化时，重新获取用户信息
  return authState.when(
    data: (state) async {
      // if (state.session == null) return null;
      // 添加小延迟确保数据库操作完成
      await Future.delayed(const Duration(milliseconds: 100));
      return ref.read(authRepositoryProvider).getCurrentProfile();
    },
    loading: () async => null,
    error: (_, __) async => null,
  );
});
