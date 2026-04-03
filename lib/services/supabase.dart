import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 客户端单例
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth 状态 Provider
final authStateProvider = StateProvider<bool>((ref) {
  return Supabase.instance.client.auth.currentSession != null;
});

/// Auth 服务
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// 发送短信验证码
  Future<void> sendCode(String phone) async {
    await _client.auth.signInWithOtp(
      phone: phone,
    );
  }

  /// 验证码登录（简化版，实际生产需要配合后端验证）
  Future<bool> verifyCode(String phone, String code) async {
    // MVP阶段：直接标记已登录，不做服务端验证码校验
    // 生产环境需要对接短信网关验证
    return true;
  }

  /// 退出登录
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// 获取当前用户
  User? get currentUser => _client.auth.currentUser;
}

/// Auth 服务 Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});
