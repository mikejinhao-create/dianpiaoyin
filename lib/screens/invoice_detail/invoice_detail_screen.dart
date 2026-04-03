import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发票详情'),
      ),
      body: Center(
        child: Text('发票ID: $invoiceId'),
      ),
    );
  }
}
