import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/profile.dart';

class AuthRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

  AuthRepository(this._isar, this._supabase);

  Future<Profile?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return _isar.profiles.filter().supabaseIdIsNull().findFirst();
    }

    // 先尝试从本地获取
    final localProfile =
        await _isar.profiles.filter().supabaseIdEqualTo(user.id).findFirst();

    if (localProfile != null) return localProfile;

    // 从服务器获取
    final response =
        await _supabase.from('profiles').select().eq('id', user.id).single();

    if (response == null) return null;

    final profile = Profile.fromJson(response);

    // 清理可能存在的冲突数据
    await _isar.writeTxn(() async {
      // 删除所有具有相同 supabaseId 的记录
      await _isar.profiles
          .filter()
          .supabaseIdEqualTo(profile.supabaseId)
          .deleteAll();

      // 删除所有具有相同 email 的记录
      await _isar.profiles.filter().emailEqualTo(profile.email).deleteAll();

      // 写入新数据
      await _isar.profiles.put(profile);
    });

    return profile;
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    // 先清除本地数据库
    await _isar.writeTxn(() async {
      await _isar.profiles.clear();
    });

    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('注册失败');
    }

    final profile = Profile(
      supabaseId: response.user!.id,
      email: email,
    );

    await _supabase.from('profiles').insert(profile.toJson());

    await _isar.writeTxn(() async {
      await _isar.profiles.put(profile);
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // 先清除本地非匿名的数据库
    await _isar.writeTxn(() async {
      final ids = await _isar.profiles
          .filter()
          .supabaseIdIsNull()
          .findAll()
          .then((value) => value.map((e) => e.id).toList());
      await _isar.profiles.deleteAll(ids);
    });

    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('登录失败');
    }

    final profile = await getCurrentProfile();
    if (profile == null) {
      throw Exception('获取用户信息失败');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _isar.writeTxn(() async {
      final ids = await _isar.profiles
          .filter()
          .supabaseIdIsNotNull()
          .findAll()
          .then((value) => value.map((e) => e.id).toList());
      await _isar.profiles.deleteAll(ids);
    });
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
