import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';
import 'supabase.dart';

/// 发票列表 Provider
final invoiceListProvider = FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;

  // TODO: 临时去掉user_id过滤，方便测试。正式上线前改回来：
  // if (user == null) return [];
  // final userIdFilter = {'user_id': user.id};

  final response = await client
      .from('invoices')
      .select()
      // .eq('user_id', user?.id ?? 1)  // 临时用user_id=1测试
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

    final query = _client
        .from('invoices')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'active');

    if (keyword != null && keyword.isNotEmpty) {
      final escaped = keyword.replaceAll('%', '%%');
      (query as dynamic).or(
        'invoice_no.ilike.%$escaped%,seller_name.ilike.%$escaped%,buyer_name.ilike.%$escaped%',
      );
    }

    final response = await (query as dynamic)
        .order('created_at', ascending: false)
        .range((page - 1) * pageSize, page * pageSize - 1);

    return (response as List).map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 手动创建发票（上传后直接插入记录，不依赖OCR）
  Future<Invoice> createInvoiceManual({
    required String fileName,
    required String fileUrl,
    required String fileType,
    String invoiceNo = '',
    String invoiceType = '普票',
    double amount = 0,
    double taxAmount = 0,
    double totalAmount = 0,
    String sellerName = '',
    String buyerName = '',
    int companyId = 1,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('未登录');

    final response = await _client.from('invoices').insert({
      'user_id': user.id,
      'company_id': companyId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'invoice_no': invoiceNo,
      'invoice_type': invoiceType,
      'amount': amount.toString(),
      'tax_amount': taxAmount.toString(),
      'total_amount': totalAmount.toString(),
      'invoice_date': DateTime.now().toIso8601String().split('T')[0],
      'seller_name': sellerName,
      'buyer_name': buyerName,
      'status': 'active',
      'print_count': 0,
    }).select().single();

    return Invoice.fromJson(response as Map<String, dynamic>);
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

  /// 批量删除（循环删除）
  Future<void> batchDelete(List<int> ids) async {
    for (final id in ids) {
      await _client.from('invoices').update({'status': 'deleted'}).eq('id', id);
    }
  }

  /// 增加打印次数
  Future<void> incrementPrintCount(int id) async {
    final current = await _client
        .from('invoices')
        .select('print_count')
        .eq('id', id)
        .single();
    final count = (current['print_count'] as int? ?? 0) + 1;
    await _client.from('invoices').update({'print_count': count}).eq('id', id);
  }
}

final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService(ref.watch(supabaseClientProvider));
});
