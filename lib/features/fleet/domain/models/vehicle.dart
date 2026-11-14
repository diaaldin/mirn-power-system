enum VehicleStatus {
  active('פעיל', 'نشط'),
  maintenance('בטיפול / מוסך', 'في الصيانة'),
  inactive('מושבת', 'غير نشط');

  final String hebrewLabel;
  final String arabicLabel;
  const VehicleStatus(this.hebrewLabel, this.arabicLabel);
}

class Vehicle {
  final String id;
  final String name; // e.g. "Volvo FH 500 Heavy Hauler"
  final String plateNumber; // e.g. "12-345-67"
  final int? modelYear;
  final int currentOdometer; // in KM
  final VehicleStatus status;
  final String? notes;

  const Vehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    this.modelYear,
    required this.currentOdometer,
    required this.status,
    this.notes,
  });

  Vehicle copyWith({
    String? id,
    String? name,
    String? plateNumber,
    int? modelYear,
    int? currentOdometer,
    VehicleStatus? status,
    String? notes,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      modelYear: modelYear ?? this.modelYear,
      currentOdometer: currentOdometer ?? this.currentOdometer,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plateNumber': plateNumber,
      'modelYear': modelYear,
      'currentOdometer': currentOdometer,
      'status': status.name,
      'notes': notes,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      name: json['name'] as String,
      plateNumber: json['plateNumber'] as String,
      modelYear: json['modelYear'] as int?,
      currentOdometer: (json['currentOdometer'] as num).toInt(),
      status: VehicleStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
    );
  }
}
