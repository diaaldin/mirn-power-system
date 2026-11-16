import '../../../fleet/domain/models/driver.dart';
import '../../../fleet/domain/models/vehicle.dart';
import '../models/dispatch.dart';

/// Input object for creating a new dispatch record.
class CreateDispatchInput {
  final String? id;
  final String dispatchNumber;
  final DateTime date;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String cargoDescription;
  final Vehicle vehicle;
  final Driver driver;
  final String? saleId;
  final String? invoiceNumber;
  final String? notes;

  const CreateDispatchInput({
    this.id,
    required this.dispatchNumber,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.cargoDescription,
    required this.vehicle,
    required this.driver,
    this.saleId,
    this.invoiceNumber,
    this.notes,
  });
}

/// Result returned from updating dispatch status, containing the updated dispatch
/// and optionally the updated vehicle if odometer changed.
class UpdateDispatchStatusResult {
  final Dispatch dispatch;
  final Vehicle? updatedVehicle;

  const UpdateDispatchStatusResult({
    required this.dispatch,
    this.updatedVehicle,
  });

  @override
  String toString() =>
      'UpdateDispatchStatusResult(dispatch: ${dispatch.dispatchNumber}, status: ${dispatch.status.name}, updatedVehicle: ${updatedVehicle?.name})';
}

/// Domain service managing dispatch creation, lifecycle state transitions,
/// and vehicle odometer synchronization.
class DispatchService {
  DispatchService._();

  static const Map<DispatchStatus, Set<DispatchStatus>> _allowedTransitions = {
    DispatchStatus.pending: {
      DispatchStatus.dispatched,
      DispatchStatus.cancelled,
    },
    DispatchStatus.dispatched: {
      DispatchStatus.delivered,
      DispatchStatus.returned,
      DispatchStatus.cancelled,
    },
    DispatchStatus.delivered: {},
    DispatchStatus.returned: {},
    DispatchStatus.cancelled: {},
  };

  /// Returns true if transitioning from [current] to [target] status is allowed.
  static bool canTransition(DispatchStatus current, DispatchStatus target) {
    return _allowedTransitions[current]?.contains(target) ?? false;
  }

  /// Returns true if [status] is a terminal state with no further transitions.
  static bool isTerminal(DispatchStatus status) {
    return _allowedTransitions[status]?.isEmpty ?? true;
  }

  /// Returns the set of valid next statuses from [current].
  static Set<DispatchStatus> allowedNextStatuses(DispatchStatus current) {
    return _allowedTransitions[current] ?? const {};
  }

  /// Validates business invariants and creates a new dispatch with `pending` status.
  static Dispatch createDispatch(CreateDispatchInput input) {
    final trimmedAddress = input.deliveryAddress.trim();
    if (trimmedAddress.isEmpty) {
      throw ArgumentError.value(
        input.deliveryAddress,
        'deliveryAddress',
        'Delivery address cannot be empty',
      );
    }

    final trimmedCargo = input.cargoDescription.trim();
    if (trimmedCargo.isEmpty) {
      throw ArgumentError.value(
        input.cargoDescription,
        'cargoDescription',
        'Cargo description cannot be empty',
      );
    }

    if (input.vehicle.status != VehicleStatus.active) {
      throw ArgumentError.value(
        input.vehicle.status,
        'vehicle',
        'Vehicle must be active to create a dispatch (current: ${input.vehicle.status.name})',
      );
    }

    if (input.driver.status != DriverStatus.active) {
      throw ArgumentError.value(
        input.driver.status,
        'driver',
        'Driver must be active to create a dispatch (current: ${input.driver.status.name})',
      );
    }

    return Dispatch(
      id: input.id ?? input.dispatchNumber,
      dispatchNumber: input.dispatchNumber,
      date: input.date,
      saleId: input.saleId,
      invoiceNumber: input.invoiceNumber,
      customerId: input.customerId,
      customerName: input.customerName,
      customerPhone: input.customerPhone,
      deliveryAddress: trimmedAddress,
      cargoDescription: trimmedCargo,
      vehicleId: input.vehicle.id,
      vehicleName: input.vehicle.name,
      plateNumber: input.vehicle.plateNumber,
      driverId: input.driver.id,
      driverName: input.driver.fullName,
      status: DispatchStatus.pending,
      notes: input.notes,
      updatedAt: input.date,
    );
  }

  /// Updates dispatch status according to state machine transition rules.
  ///
  /// When transitioning to `delivered` with [vehicle] and [completionOdometer],
  /// validates that [completionOdometer] >= vehicle.currentOdometer and returns
  /// the updated vehicle with the new odometer reading.
  static UpdateDispatchStatusResult updateDispatchStatus({
    required Dispatch dispatch,
    required DispatchStatus newStatus,
    DateTime? updatedAt,
    String? notes,
    Vehicle? vehicle,
    int? completionOdometer,
  }) {
    if (!canTransition(dispatch.status, newStatus)) {
      throw StateError(
        'Invalid status transition: cannot move dispatch ${dispatch.dispatchNumber} '
        'from ${dispatch.status.name} to ${newStatus.name}',
      );
    }

    final effectiveUpdatedAt = updatedAt ?? DateTime.now();
    final updatedDispatch = dispatch.copyWith(
      status: newStatus,
      notes: notes ?? dispatch.notes,
      updatedAt: effectiveUpdatedAt,
    );

    Vehicle? updatedVehicle;
    if (newStatus == DispatchStatus.delivered &&
        vehicle != null &&
        completionOdometer != null) {
      if (completionOdometer < vehicle.currentOdometer) {
        throw ArgumentError.value(
          completionOdometer,
          'completionOdometer',
          'Completion odometer ($completionOdometer) cannot be lower than current vehicle odometer (${vehicle.currentOdometer})',
        );
      }
      updatedVehicle = vehicle.copyWith(currentOdometer: completionOdometer);
    }

    return UpdateDispatchStatusResult(
      dispatch: updatedDispatch,
      updatedVehicle: updatedVehicle,
    );
  }
}
