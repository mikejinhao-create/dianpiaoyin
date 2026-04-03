import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/invoice.dart';
import '../../services/invoice_service.dart';

class PrintPreviewScreen extends ConsumerStatefulWidget {
  final List<int> invoiceIds;

  const PrintPreviewScreen({super.key, required this.invoiceIds});

  @override
  ConsumerState<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends ConsumerState<PrintPreviewScreen> {
  List<Invoice> _invoices = [];
  bool _loading = true;
  String _paperSize = 'A4';
  double _scale = 1.0;
  int _copies = 1;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    if (widget.invoiceIds.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final service = ref.read(invoiceServiceProvider);
      final invoices = <Invoice>[];
      for (final id in widget.invoiceIds) {
        final invoice = await service.getInvoice(id);
        if (invoice != null) invoices.add(invoice);
      }
      setState(() {
        _invoices = invoices;
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

  Future<void> _print() async {
    if (_invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可打印的发票')),
      );
      return;
    }

    try {
      // 生成PDF
      final pdf = pw.Document();

      for (int i = 0; i < _copies; i++) {
        for (final invoice in _invoices) {
          pdf.addPage(
            pw.Page(
              pageFormat: _paperSize == 'A4'
                  ? PdfPageFormat.a4
                  : PdfPageFormat.a4.landscape,
              build: (context) => pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      invoice.sellerName.isNotEmpty
                          ? invoice.sellerName
                          : '销售方',
                      style: const pw.TextStyle(fontSize: 18),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text('发票号: ${invoice.invoiceNo}'),
                    pw.Text('金额: ¥${invoice.totalAmount}'),
                    pw.Text('日期: ${invoice.invoiceDate}'),
                  ],
                ),
              ),
            ),
          );
        }
      }

      // 调用系统打印
      await Printing.layoutPdf(
        onLayout: (format) => pdf.save(),
        name: '电票印打印',
      );

      // 增加打印计数
      final service = ref.read(invoiceServiceProvider);
      for (final id in widget.invoiceIds) {
        await service.incrementPrintCount(id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打印任务已发送')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打印失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('打印预览')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('打印预览'),
      ),
      body: Column(
        children: [
          // 预览区
          Expanded(
            child: _invoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print_disabled, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '没有选择发票',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '请从发票列表选择发票',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AspectRatio(
                      aspectRatio: 1 / 1.414, // A4比例
                      child: _buildPreview(),
                    ),
                  ),
          ),

          // 打印设置
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // 纸张大小
                Row(
                  children: [
                    const Text('纸张', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('A4纵向'),
                      selected: _paperSize == 'A4',
                      onSelected: (_) => setState(() => _paperSize = 'A4'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('A4横向'),
                      selected: _paperSize == 'A4_LANDSCAPE',
                      onSelected: (_) => setState(() => _paperSize = 'A4_LANDSCAPE'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 缩放比例
                Row(
                  children: [
                    const Text('缩放', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Slider(
                        value: _scale,
                        min: 0.5,
                        max: 2.0,
                        divisions: 6,
                        label: '${(_scale * 100).round()}%',
                        onChanged: (v) => setState(() => _scale = v),
                      ),
                    ),
                    Text('${(_scale * 100).round()}%'),
                  ],
                ),
                const SizedBox(height: 16),

                // 份数
                Row(
                  children: [
                    const Text('份数', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _copies > 1
                          ? () => setState(() => _copies--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_copies',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: _copies < 10
                          ? () => setState(() => _copies++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 打印按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _invoices.isEmpty ? null : _print,
                    icon: const Icon(Icons.print),
                    label: Text('立即打印 (${_invoices.length}张 × $_copies份)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _invoices.asMap().entries.map((entry) {
          final index = entry.key;
          final invoice = entry.value;
          return Container(
            key: ValueKey(invoice.id),
            margin: EdgeInsets.only(bottom: index < _invoices.length - 1 ? 16 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text(
                  invoice.sellerName.isNotEmpty ? invoice.sellerName : '销售方',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '¥${invoice.totalAmount}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  invoice.invoiceNo,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
