import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrintPreviewScreen extends ConsumerWidget {
  final List<int> invoiceIds;

  const PrintPreviewScreen({super.key, required this.invoiceIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('打印预览'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '打印功能开发中...',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              '触屏自由排版\n多发票组合打印\n即将上线',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
