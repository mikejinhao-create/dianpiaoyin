/// 打印记录模型
class PrintLog {
  final int id;
  final int userId;
  final int invoiceId;
  final DateTime printedAt;
  final String printerName;
  final int copyCount;

  PrintLog({
    required this.id,
    required this.userId,
    required this.invoiceId,
    required this.printedAt,
    required this.printerName,
    required this.copyCount,
  });

  factory PrintLog.fromJson(Map<String, dynamic> json) {
    return PrintLog(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      invoiceId: json['invoice_id'] as int,
      printedAt: DateTime.parse(json['printed_at'] as String),
      printerName: json['printer_name'] as String? ?? '',
      copyCount: json['copy_count'] as int? ?? 1,
    );
  }
}
