import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/invoice.dart';
import '../../services/invoice_service.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    try {
      final service = ref.read(invoiceServiceProvider);
      final invoice = await service.getInvoice(widget.invoiceId);
      setState(() {
        _invoice = invoice;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteInvoice() async {
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
      try {
        await ref.read(invoiceServiceProvider).deleteInvoice(widget.invoiceId);
        if (mounted) context.go('/invoices');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('发票详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_invoice == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('发票详情')),
        body: const Center(child: Text('发票不存在')),
      );
    }

    final invoice = _invoice!;
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currencyFormat = NumberFormat.currency(symbol: '¥');

    return Scaffold(
      appBar: AppBar(
        title: const Text('发票详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteInvoice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 发票头部信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: invoice.invoiceType == '专票'
                                ? Colors.orange[50]
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            invoice.invoiceType.isNotEmpty ? invoice.invoiceType : '普票',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: invoice.invoiceType == '专票'
                                  ? Colors.orange[700]
                                  : Colors.blue[700],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          currencyFormat.format(invoice.totalAmount),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _infoRow('发票号码', invoice.invoiceNo.isNotEmpty ? invoice.invoiceNo : '—'),
                    _infoRow('开票日期', dateFormat.format(invoice.invoiceDate)),
                    _infoRow('销售方', invoice.sellerName.isNotEmpty ? invoice.sellerName : '—'),
                    _infoRow('购买方', invoice.buyerName.isNotEmpty ? invoice.buyerName : '—'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 金额明细
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '金额明细',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(),
                    _infoRow('金额', currencyFormat.format(invoice.amount)),
                    _infoRow('税额', currencyFormat.format(invoice.taxAmount)),
                    const Divider(),
                    _infoRow('价税合计', currencyFormat.format(invoice.totalAmount)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 文件信息
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '文件信息',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(),
                    _infoRow('文件名', invoice.fileName),
                    _infoRow('文件格式', invoice.fileType.toUpperCase()),
                    _infoRow('打印次数', '${invoice.printCount}次'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => context.go('/print', extra: [invoice.id]),
            icon: const Icon(Icons.print),
            label: const Text('打印发票'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
