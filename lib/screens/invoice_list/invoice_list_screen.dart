import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/invoice.dart';
import '../../services/invoice_service.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final _searchController = TextEditingController();
  String? _selectedCompanyId;
  bool _isLoading = false;
  List<Invoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(invoiceServiceProvider);
      final invoices = await service.getInvoices(
        companyId: _selectedCompanyId != null ? int.parse(_selectedCompanyId!) : null,
        keyword: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteInvoice(int id) async {
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
        await ref.read(invoiceServiceProvider).deleteInvoice(id);
        _loadInvoices();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('发票列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索发票号/公司名',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadInvoices();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadInvoices(),
            ),
          ),
          // 发票列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadInvoices,
                        child: ListView.builder(
                          itemCount: _invoices.length,
                          itemBuilder: (context, index) {
                            final invoice = _invoices[index];
                            return _buildInvoiceCard(invoice);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/'),
        icon: const Icon(Icons.add),
        label: const Text('导入发票'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ? '没有找到发票' : '暂无发票',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? '试试其他关键词'
                : '从微信或相册导入发票\n即可在此查看',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice invoice) {
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
                    onPressed: () => _deleteInvoice(invoice.id),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
