import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/invoice.dart';
import '../../services/invoice_service.dart';

final invoiceListProvider = FutureProvider.autoDispose<List<Invoice>>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  final response = await client
      .from('invoices')
      .select()
      .eq('status', 'active')
      .order('created_at', ascending: false)
      .limit(100);

  return (response as List).map((e) => Invoice.fromJson(e as Map<String, dynamic>)).toList();
});

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceList = ref.watch(invoiceListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('发票列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(invoiceListProvider),
          ),
        ],
      ),
      body: invoiceList.when(
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无发票',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '从微信或相册导入发票\n即可在此查看',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.refresh(invoiceListProvider);
            },
            child: ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return _InvoiceCard(invoice: invoice, ref: ref);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 8),
              Text('加载失败: $e', style: TextStyle(color: Colors.grey[600])),
              TextButton(
                onPressed: () => ref.refresh(invoiceListProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/'),
        icon: const Icon(Icons.add),
        label: const Text('导入发票'),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final WidgetRef ref;

  const _InvoiceCard({required this.invoice, required this.ref});

  Future<void> _deleteInvoice(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除发票'),
        content: const Text('确定要删除这张发票吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(invoiceServiceProvider).deleteInvoice(invoice.id);
      ref.refresh(invoiceListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencyFormat = NumberFormat.currency(symbol: '¥');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => context.go('/invoice/${invoice.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt, size: 20, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      invoice.sellerName.isNotEmpty ? invoice.sellerName : '未知销售方',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: invoice.invoiceType == '专票'
                          ? Colors.orange[50]
                          : Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      invoice.invoiceType.isNotEmpty ? invoice.invoiceType : '普票',
                      style: TextStyle(
                        fontSize: 12,
                        color: invoice.invoiceType == '专票'
                            ? Colors.orange[700]
                            : Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '发票号: ${invoice.invoiceNo.isNotEmpty ? invoice.invoiceNo : "—"}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '日期: ${dateFormat.format(invoice.invoiceDate)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(invoice.totalAmount),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      if (invoice.printCount > 0)
                        Text(
                          '已打印${invoice.printCount}次',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _deleteInvoice(context),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('删除'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[400],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/print', extra: [invoice.id]),
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('打印'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
