class LabTest {
  final int id;
  final int labId;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? preparationRequired;
  final String? sampleType;
  final String? reportDeliveryTime;
  final bool isAvailable;

  LabTest({
    required this.id,
    required this.labId,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.preparationRequired,
    this.sampleType,
    this.reportDeliveryTime,
    required this.isAvailable,
  });

  factory LabTest.fromJson(Map<String, dynamic> json) {
    return LabTest(
      id: json['id'],
      labId: json['lab_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] ?? 0.0).toDouble(),
      category: json['category'],
      preparationRequired: json['preparation_required'],
      sampleType: json['sample_type'],
      reportDeliveryTime: json['report_delivery_time'],
      isAvailable: json['is_available'] ?? true,
    );
  }
}

class LabTestOrder {
  final int id;
  final int patientId;
  final int labId;
  final String orderDate;
  final String? testDate;
  final String? testTime;
  final String status;
  final double totalAmount;
  final String paymentStatus;
  final String? collectionAddress;
  final String? notes;
  final List<LabTestOrderItem>? items;

  LabTestOrder({
    required this.id,
    required this.patientId,
    required this.labId,
    required this.orderDate,
    this.testDate,
    this.testTime,
    required this.status,
    required this.totalAmount,
    required this.paymentStatus,
    this.collectionAddress,
    this.notes,
    this.items,
  });

  factory LabTestOrder.fromJson(Map<String, dynamic> json) {
    return LabTestOrder(
      id: json['id'],
      patientId: json['patient_id'],
      labId: json['lab_id'],
      orderDate: json['order_date'],
      testDate: json['test_date'],
      testTime: json['test_time'],
      status: json['status'],
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      paymentStatus: json['payment_status'],
      collectionAddress: json['collection_address'],
      notes: json['notes'],
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => LabTestOrderItem.fromJson(item))
              .toList()
          : null,
    );
  }
}

class LabTestOrderItem {
  final int id;
  final int orderId;
  final int testId;
  final double price;
  final LabTest? test;

  LabTestOrderItem({
    required this.id,
    required this.orderId,
    required this.testId,
    required this.price,
    this.test,
  });

  factory LabTestOrderItem.fromJson(Map<String, dynamic> json) {
    return LabTestOrderItem(
      id: json['id'],
      orderId: json['order_id'],
      testId: json['test_id'],
      price: (json['price'] ?? 0.0).toDouble(),
      test: json['test'] != null ? LabTest.fromJson(json['test']) : null,
    );
  }
}

class LabReport {
  final int id;
  final int orderId;
  final int patientId;
  final String reportDate;
  final String? reportFileUrl;
  final String? findings;
  final String? remarks;

  LabReport({
    required this.id,
    required this.orderId,
    required this.patientId,
    required this.reportDate,
    this.reportFileUrl,
    this.findings,
    this.remarks,
  });

  factory LabReport.fromJson(Map<String, dynamic> json) {
    return LabReport(
      id: json['id'],
      orderId: json['order_id'],
      patientId: json['patient_id'],
      reportDate: json['report_date'],
      reportFileUrl: json['report_file_url'],
      findings: json['findings'],
      remarks: json['remarks'],
    );
  }
}
