enum DispatchStatus {
  pending('ממתין להעמסה', 'قيد الانتظار'),
  dispatched('יצא לדרך', 'في الطريق'),
  delivered('נמסר ללקוח', 'تم التسليم'),
  returned('הוחזר', 'معاد'),
  cancelled('מבוטל', 'ملغي');

  final String hebrewLabel;
  final String arabicLabel;
  const DispatchStatus(this.hebrewLabel, this.arabicLabel);
}

class Dispatch {
  final String id;
  final String dispatchNumber; // DSP-2026-xxxxx
  final DateTime date;
  final String? saleId;
  final String? invoiceNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String cargoDescription;
  final String vehicleId;
  final String vehicleName;
  final String plateNumber;
  final String driverId;
  final String driverName;
  final DispatchStatus status;
  final String? notes;
  final DateTime updatedAt;

  const Dispatch({
    required this.id,
    required this.dispatchNumber,
    required this.date,
    this.saleId,
    this.invoiceNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.cargoDescription,
    required this.vehicleId,
    required this.vehicleName,
    required this.plateNumber,
    required this.driverId,
    required this.driverName,
    required this.status,
    this.notes,
    required this.updatedAt,
  });

  Dispatch copyWith({
    String? id,
    String? dispatchNumber,
    DateTime? date,
    String? saleId,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? cargoDescription,
    String? vehicleId,
    String? vehicleName,
    String? plateNumber,
    String? driverId,
    String? driverName,
    DispatchStatus? status,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Dispatch(
      id: id ?? this.id,
      dispatchNumber: dispatchNumber ?? this.dispatchNumber,
      date: date ?? this.date,
      saleId: saleId ?? this.saleId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      cargoDescription: cargoDescription ?? this.cargoDescription,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleName: vehicleName ?? this.vehicleName,
      plateNumber: plateNumber ?? this.plateNumber,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dispatchNumber': dispatchNumber,
      'date': date.toIso8601String(),
      'saleId': saleId,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'cargoDescription': cargoDescription,
      'vehicleId': vehicleId,
      'vehicleName': vehicleName,
      'plateNumber': plateNumber,
      'driverId': driverId,
      'driverName': driverName,
      'status': status.name,
      'notes': notes,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Dispatch.fromJson(Map<String, dynamic> json) {
    return Dispatch(
      id: json['id'] as String,
      dispatchNumber: json['dispatchNumber'] as String,
      date: DateTime.parse(json['date'] as String),
      saleId: json['saleId'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] as String,
      cargoDescription: json['cargoDescription'] as String,
      vehicleId: json['vehicleId'] as String,
      vehicleName: json['vehicleName'] as String,
      plateNumber: json['plateNumber'] as String,
      driverId: json['driverId'] as String,
      driverName: json['driverName'] as String,
      status: DispatchStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
