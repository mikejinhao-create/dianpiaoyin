import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase.dart';

/// 发票文件上传服务
class InvoiceUploadService {
  final SupabaseClient _client;

  InvoiceUploadService(this._client);

  /// 上传发票文件到 Supabase Storage
  /// 返回公开访问URL
  Future<String> uploadFile({
    required String filePath,
    required String fileName,
    required Uint8List bytes,
  }) async {
    // TODO: 临时用user_id=1测试，正式上线要改回真实用户
    final userId = 1; // 临时硬编码

    final storagePath = 'invoices/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from('invoices').uploadBinary(
      storagePath,
      bytes,
    );

    // 返回公开URL（临时方案，正式环境用签名URL）
    final publicUrl = 'https://fmeiawlltymosqhusmwb.supabase.co/storage/v1/object/public/$storagePath';
    return publicUrl;
  }
}

final invoiceUploadServiceProvider = Provider<InvoiceUploadService>((ref) {
  return InvoiceUploadService(ref.watch(supabaseClientProvider));
});
