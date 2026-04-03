import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';
import 'supabase.dart';

/// 发票列表 Provider
final invoiceListProvider = FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return [];

  final response = await client
      .from('invoices')
      .select()
      .eq('user_id', user.id)
      .eq('status', 'active')
      .order('created_at', ascending: false)
      .limit(100);

  return (response as List).map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
});

/// 发票服务
class InvoiceService {
  final SupabaseClient _client;

  InvoiceService(this._client);

  /// 上传发票文件
  Future<Invoice> uploadInvoice({
    required String filePath,
    required String fileName,
    required String fileType,
    required int companyId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('未登录');

    // 上传文件到 Supabase Storage
    final fileUrl = 'invoices/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('invoices').upload(
      fileUrl,
      Uint8List(0),
    );

    // 创建发票记录
    final response = await _client.from('invoices').insert({
      'user_id': user.id,
      'company_id': companyId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'status': 'active',
    }).select().single();

    return Invoice.fromJson(response as Map<String, dynamic>);
  }

  /// 获取发票列表
  Future<List<Invoice>> getInvoices({
    int? companyId,
    String? keyword,
    int page = 1,
    int pageSize = 20,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // 构建基础查询：select + 基础过滤
    PostgrestBuilder baseQuery = _client
        .from('invoices')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'active');

    // 按公司筛选
    if (companyId != null) {
      baseQuery = (baseQuery as dynamic).eq('company_id', companyId);
    }

    // 搜索关键词
    if (keyword != null && keyword.isNotEmpty) {
      final escaped = keyword.replaceAll('%', '%%');
      baseQuery = (baseQuery as dynamic).or(
        'invoice_no.ilike.%$escaped%,seller_name.ilike.%$escaped%,buyer_name.ilike.%$escaped%',
      );
    }

    // 分页
    final response = await (baseQuery as dynamic)
        .order('created_at', ascending: false)
        .range((page - 1) * pageSize, page * pageSize - 1);

    return (response as List).map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取单个发票
  Future<Invoice?> getInvoice(int id) async {
    final response = await _client
        .from('invoices')
        .select()
        .eq('id', id)
        .single();
    return Invoice.fromJson(response as Map<String, dynamic>);
  }

  /// 更新发票
  Future<void> updateInvoice(int id, Map<String, dynamic> data) async {
    await _client.from('invoices').update(data).eq('id', id);
  }

  /// 删除发票（软删除）
  Future<void> deleteInvoice(int id) async {
    await _client.from('invoices').update({'status': 'deleted'}).eq('id', id);
  }

  /// 批量删除
  Future<void> batchDelete(List<int> ids) async {
    await _client.from('invoices').update({'status': 'deleted'}).in_('id', ids);
  }
}

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService(ref.watch(supabaseClientProvider));
});
