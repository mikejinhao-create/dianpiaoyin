/// 发票模型
class Invoice {
  final int id;
  final int userId;
  final int companyId;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final String invoiceNo;
  final String invoiceType;
  final double amount;
  final double taxAmount;
  final double totalAmount;
  final DateTime invoiceDate;
  final String sellerName;
  final String buyerName;
  final String status;
  final int printCount;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    required this.invoiceNo,
    required this.invoiceType,
    required this.amount,
    required this.taxAmount,
    required this.totalAmount,
    required this.invoiceDate,
    required this.sellerName,
    required this.buyerName,
    required this.status,
    required this.printCount,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      companyId: json['company_id'] as int,
      fileName: json['file_name'] as String? ?? '',
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String? ?? '',
      invoiceNo: json['invoice_no'] as String? ?? '',
      invoiceType: json['invoice_type'] as String? ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      invoiceDate: json['invoice_date'] != null
          ? DateTime.parse(json['invoice_date'] as String)
          : DateTime.now(),
      sellerName: json['seller_name'] as String? ?? '',
      buyerName: json['buyer_name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      printCount: json['print_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company_id': companyId,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_type': fileType,
      'invoice_no': invoiceNo,
      'invoice_type': invoiceType,
      'amount': amount.toString(),
      'tax_amount': taxAmount.toString(),
      'total_amount': totalAmount.toString(),
      'invoice_date': invoiceDate.toIso8601String().split('T')[0],
      'seller_name': sellerName,
      'buyer_name': buyerName,
      'status': status,
      'print_count': printCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
