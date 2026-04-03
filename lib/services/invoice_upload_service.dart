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
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('未登录');

    final storagePath = 'invoices/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await _client.storage.from('invoices').uploadBinary(
      storagePath,
      bytes,
      options: FileOptions(
        contentType: _getContentType(fileName),
      ),
    );

    // 返回公开URL（临时方案，正式环境用签名URL）
    final publicUrl = 'https://fmeiawlltymosqhusmwb.supabase.co/storage/v1/object/public/$storagePath';
    return publicUrl;
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'ofd':
        return 'application/x-ofd';
      default:
        return 'application/octet-stream';
    }
  }
}

final invoiceUploadServiceProvider = Provider<InvoiceUploadService>((ref) {
  return InvoiceUploadService(ref.watch(supabaseClientProvider));
});
