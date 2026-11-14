enum DriverStatus {
  active('פעיל', 'نشط'),
  inactive('לא פעיל', 'غير نشط');

  final String hebrewLabel;
  final String arabicLabel;
  const DriverStatus(this.hebrewLabel, this.arabicLabel);
}

class Driver {
  final String id;
  final String fullName;
  final String phone;
  final String licenseNumber;
  final DriverStatus status;
  final String? notes;

  const Driver({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.licenseNumber,
    required this.status,
    this.notes,
  });

  Driver copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? licenseNumber,
    DriverStatus? status,
    String? notes,
  }) {
    return Driver(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'status': status.name,
      'notes': notes,
    };
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      licenseNumber: json['licenseNumber'] as String,
      status: DriverStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
    );
  }
}
