import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../services/invoice_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已选择图片: ${image.name}')),
          );
        }
        // TODO: 上传到服务器 + 调用OCR
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoiceList = ref.watch(invoiceListProvider);
    final currencyFormat = NumberFormat.currency(symbol: '¥');

    return Scaffold(
      appBar: AppBar(
        title: const Text('电票印'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 快捷操作区
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.qr_code_scanner,
                    label: '扫码',
                    color: Colors.blue,
                    onTap: () {
                      // TODO: 打开扫码功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('扫码功能开发中...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.photo_library,
                    label: '相册',
                    color: Colors.green,
                    onTap: _pickImage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.print,
                    label: '打印',
                    color: Colors.orange,
                    onTap: () => context.go('/invoices'),
                  ),
                ),
              ],
            ),
          ),

          // 最近发票区
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '最近发票',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/invoices'),
                  child: const Text('查看全部'),
                ),
              ],
            ),
          ),

          // 发票列表
          Expanded(
            child: invoiceList.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          '暂无发票',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '从微信或相册导入发票',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: invoices.length > 5 ? 5 : invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => context.go('/invoice/${invoice.id}'),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: Icon(Icons.receipt, color: Colors.blue[700]),
                        ),
                        title: Text(
                          invoice.sellerName.isNotEmpty
                              ? invoice.sellerName
                              : '未知销售方',
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd').format(invoice.invoiceDate),
                        ),
                        trailing: Text(
                          currencyFormat.format(invoice.totalAmount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    );
                  },
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
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
