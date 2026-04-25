class Medicine {
  final int id;
  final int storeId;
  final String name;
  final String? description;
  final String? manufacturer;
  final double price;
  final int stockQuantity;
  final String? expiryDate;
  final String? category;
  final bool requiresPrescription;
  final bool isAvailable;

  Medicine({
    required this.id,
    required this.storeId,
    required this.name,
    this.description,
    this.manufacturer,
    required this.price,
    required this.stockQuantity,
    this.expiryDate,
    this.category,
    required this.requiresPrescription,
    required this.isAvailable,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      storeId: json['store_id'],
      name: json['name'],
      description: json['description'],
      manufacturer: json['manufacturer'],
      price: (json['price'] ?? 0.0).toDouble(),
      stockQuantity: json['stock_quantity'] ?? 0,
      expiryDate: json['expiry_date'],
      category: json['category'],
      requiresPrescription: json['requires_prescription'] ?? false,
      isAvailable: json['is_available'] ?? true,
    );
  }
}

class MedicineOrder {
  final int id;
  final int patientId;
  final int storeId;
  final String orderDate;
  final String status;
  final double totalAmount;
  final String paymentStatus;
  final String? deliveryAddress;
  final String? notes;
  final List<MedicineOrderItem>? items;

  MedicineOrder({
    required this.id,
    required this.patientId,
    required this.storeId,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    required this.paymentStatus,
    this.deliveryAddress,
    this.notes,
    this.items,
  });

  factory MedicineOrder.fromJson(Map<String, dynamic> json) {
    return MedicineOrder(
      id: json['id'],
      patientId: json['patient_id'],
      storeId: json['store_id'],
      orderDate: json['order_date'],
      status: json['status'],
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      paymentStatus: json['payment_status'],
      deliveryAddress: json['delivery_address'],
      notes: json['notes'],
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => MedicineOrderItem.fromJson(item))
              .toList()
          : null,
    );
  }
}

class MedicineOrderItem {
  final int id;
  final int orderId;
  final int medicineId;
  final int quantity;
  final double price;
  final Medicine? medicine;

  MedicineOrderItem({
    required this.id,
    required this.orderId,
    required this.medicineId,
    required this.quantity,
    required this.price,
    this.medicine,
  });

  factory MedicineOrderItem.fromJson(Map<String, dynamic> json) {
    return MedicineOrderItem(
      id: json['id'],
      orderId: json['order_id'],
      medicineId: json['medicine_id'],
      quantity: json['quantity'],
      price: (json['price'] ?? 0.0).toDouble(),
      medicine: json['medicine'] != null
          ? Medicine.fromJson(json['medicine'])
          : null,
    );
  }
}
