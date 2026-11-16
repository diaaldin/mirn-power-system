import '../../../fleet/domain/models/driver.dart';
import '../../../fleet/domain/models/vehicle.dart';
import '../../domain/models/dispatch.dart';
import '../../domain/services/dispatch_service.dart';

/// Immutable snapshot of the FleetDispatchController state.
class FleetDispatchState {
  // All dispatches and filtered view
  final List<Dispatch> dispatches;
  final List<Dispatch> filteredDispatches;
  final DispatchStatus? statusFilter;

  // New dispatch form draft
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? vehicleId;
  final String? vehicleName;
  final String? plateNumber;
  final VehicleStatus? vehicleStatus;
  final int? vehicleOdometer;
  final String? driverId;
  final String? driverName;
  final DriverStatus? driverStatus;
  final String deliveryAddress;
  final String cargoDescription;
  final String? invoiceNumber;
  final String? saleId;
  final String? formNotes;

  // UI state
  final bool isSubmitting;
  final String? errorMessage;
  final Dispatch? lastCreatedDispatch;

  const FleetDispatchState({
    this.dispatches = const [],
    this.filteredDispatches = const [],
    this.statusFilter,
    this.customerId = '',
    this.customerName = '',
    this.customerPhone = '',
    this.vehicleId,
    this.vehicleName,
    this.plateNumber,
    this.vehicleStatus,
    this.vehicleOdometer,
    this.driverId,
    this.driverName,
    this.driverStatus,
    this.deliveryAddress = '',
    this.cargoDescription = '',
    this.invoiceNumber,
    this.saleId,
    this.formNotes,
    this.isSubmitting = false,
    this.errorMessage,
    this.lastCreatedDispatch,
  });

  FleetDispatchState copyWith({
    List<Dispatch>? dispatches,
    List<Dispatch>? filteredDispatches,
    DispatchStatus? statusFilter,
    bool clearStatusFilter = false,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? vehicleId,
    bool clearVehicleId = false,
    String? vehicleName,
    bool clearVehicleName = false,
    String? plateNumber,
    bool clearPlateNumber = false,
    VehicleStatus? vehicleStatus,
    bool clearVehicleStatus = false,
    int? vehicleOdometer,
    bool clearVehicleOdometer = false,
    String? driverId,
    bool clearDriverId = false,
    String? driverName,
    bool clearDriverName = false,
    DriverStatus? driverStatus,
    bool clearDriverStatus = false,
    String? deliveryAddress,
    String? cargoDescription,
    String? invoiceNumber,
    bool clearInvoiceNumber = false,
    String? saleId,
    bool clearSaleId = false,
    String? formNotes,
    bool clearFormNotes = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearErrorMessage = false,
    Dispatch? lastCreatedDispatch,
    bool clearLastCreatedDispatch = false,
  }) {
    return FleetDispatchState(
      dispatches: dispatches ?? this.dispatches,
      filteredDispatches: filteredDispatches ?? this.filteredDispatches,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehicleId: clearVehicleId ? null : (vehicleId ?? this.vehicleId),
      vehicleName: clearVehicleName ? null : (vehicleName ?? this.vehicleName),
      plateNumber: clearPlateNumber ? null : (plateNumber ?? this.plateNumber),
      vehicleStatus: clearVehicleStatus ? null : (vehicleStatus ?? this.vehicleStatus),
      vehicleOdometer: clearVehicleOdometer ? null : (vehicleOdometer ?? this.vehicleOdometer),
      driverId: clearDriverId ? null : (driverId ?? this.driverId),
      driverName: clearDriverName ? null : (driverName ?? this.driverName),
      driverStatus: clearDriverStatus ? null : (driverStatus ?? this.driverStatus),
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      cargoDescription: cargoDescription ?? this.cargoDescription,
      invoiceNumber: clearInvoiceNumber ? null : (invoiceNumber ?? this.invoiceNumber),
      saleId: clearSaleId ? null : (saleId ?? this.saleId),
      formNotes: clearFormNotes ? null : (formNotes ?? this.formNotes),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      lastCreatedDispatch: clearLastCreatedDispatch
          ? null
          : (lastCreatedDispatch ?? this.lastCreatedDispatch),
    );
  }
}

/// Presentation controller managing the state machine for fleet dispatches:
/// dispatch list, status filter, new dispatch form, and status transitions.
class FleetDispatchController {
  FleetDispatchState _state;

  /// Sequential counter for DSP numbers (1-based, incremented after each submit).
  int _nextDispatchSeq;

  FleetDispatchController({
    List<Dispatch> initial = const [],
    int initialSeq = 1,
  })  : _state = FleetDispatchState(
          dispatches: List.unmodifiable(initial),
          filteredDispatches: List.unmodifiable(initial),
        ),
        _nextDispatchSeq = initialSeq;

  FleetDispatchState get state => _state;

  // ── Form setters ─────────────────────────────────────────────────────────────

  void setCustomer({
    required String id,
    required String name,
    required String phone,
  }) {
    _state = _state.copyWith(
      customerId: id,
      customerName: name,
      customerPhone: phone,
    );
    _applyFilter();
  }

  void setVehicle({
    required String id,
    required String name,
    required String plateNumber,
    VehicleStatus status = VehicleStatus.active,
    int currentOdometer = 0,
  }) {
    _state = _state.copyWith(
      vehicleId: id,
      vehicleName: name,
      plateNumber: plateNumber,
      vehicleStatus: status,
      vehicleOdometer: currentOdometer,
    );
    _applyFilter();
  }

  void setDriver({
    required String id,
    required String name,
    DriverStatus status = DriverStatus.active,
  }) {
    _state = _state.copyWith(
      driverId: id,
      driverName: name,
      driverStatus: status,
    );
    _applyFilter();
  }

  void setDeliveryAddress(String address) {
    _state = _state.copyWith(deliveryAddress: address);
    _applyFilter();
  }

  void setCargoDescription(String cargo) {
    _state = _state.copyWith(cargoDescription: cargo);
    _applyFilter();
  }

  void setInvoiceRef({String? saleId, String? invoiceNumber}) {
    _state = _state.copyWith(
      saleId: saleId,
      clearSaleId: saleId == null,
      invoiceNumber: invoiceNumber,
      clearInvoiceNumber: invoiceNumber == null,
    );
    _applyFilter();
  }

  void setFormNotes(String? notes) {
    _state = _state.copyWith(
      formNotes: notes,
      clearFormNotes: notes == null,
    );
    _applyFilter();
  }

  // ── Filter ────────────────────────────────────────────────────────────────────

  void setStatusFilter(DispatchStatus? status) {
    _state = _state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
    _applyFilter();
  }

  // ── Dispatch number generator ─────────────────────────────────────────────────

  String _generateDispatchNumber(DateTime date) {
    final seq = _nextDispatchSeq.toString().padLeft(5, '0');
    return 'DSP-${date.year}-$seq';
  }

  // ── Submit new dispatch ───────────────────────────────────────────────────────

  /// Validates form fields, creates the dispatch via [DispatchService], adds it
  /// to the list, resets the form, and returns the new [Dispatch].
  ///
  /// Throws [StateError] when customer, vehicle, or driver is not selected.
  /// Throws [ArgumentError] (from [DispatchService]) when address or cargo is blank.
  Dispatch submitNewDispatch({DateTime? date}) {
    final s = _state;

    // Validate required selections
    if (s.customerId.trim().isEmpty) {
      throw StateError('No customer selected');
    }
    if (s.vehicleId == null || s.vehicleId!.trim().isEmpty) {
      throw StateError('No vehicle selected');
    }
    if (s.driverId == null || s.driverId!.trim().isEmpty) {
      throw StateError('No driver selected');
    }

    final effectiveDate = date ?? DateTime.now();
    final dispatchNumber = _generateDispatchNumber(effectiveDate);

    // Build mock Vehicle and Driver from form state
    final mockVehicle = Vehicle(
      id: s.vehicleId!,
      name: s.vehicleName ?? s.vehicleId!,
      plateNumber: s.plateNumber ?? '',
      currentOdometer: s.vehicleOdometer ?? 0,
      status: s.vehicleStatus ?? VehicleStatus.active,
    );

    final mockDriver = Driver(
      id: s.driverId!,
      fullName: s.driverName ?? s.driverId!,
      phone: '',
      licenseNumber: '',
      status: s.driverStatus ?? DriverStatus.active,
    );

    // May throw ArgumentError for blank address/cargo (let it propagate)
    final dispatch = DispatchService.createDispatch(
      CreateDispatchInput(
        dispatchNumber: dispatchNumber,
        date: effectiveDate,
        customerId: s.customerId,
        customerName: s.customerName,
        customerPhone: s.customerPhone,
        deliveryAddress: s.deliveryAddress,
        cargoDescription: s.cargoDescription,
        vehicle: mockVehicle,
        driver: mockDriver,
        saleId: s.saleId,
        invoiceNumber: s.invoiceNumber,
        notes: s.formNotes,
      ),
    );

    _nextDispatchSeq++;

    final updatedDispatches = List<Dispatch>.unmodifiable([
      ..._state.dispatches,
      dispatch,
    ]);

    // Reset form fields but keep dispatch list and filter
    _state = FleetDispatchState(
      dispatches: updatedDispatches,
      statusFilter: _state.statusFilter,
      lastCreatedDispatch: dispatch,
    );
    _applyFilter();

    return dispatch;
  }

  // ── Status transitions ────────────────────────────────────────────────────────

  /// Advances a dispatch to [newStatus]. Optionally updates vehicle odometer when
  /// delivering. Returns [UpdateDispatchStatusResult] from [DispatchService].
  ///
  /// Throws [StateError] if the dispatch is in a terminal state or the transition
  /// is otherwise invalid.
  UpdateDispatchStatusResult advanceStatus({
    required String dispatchId,
    required DispatchStatus newStatus,
    Vehicle? vehicle,
    int? completionOdometer,
    String? notes,
  }) {
    final dispatch = _findDispatch(dispatchId);

    if (DispatchService.isTerminal(dispatch.status)) {
      throw StateError(
        'Cannot advance dispatch ${dispatch.dispatchNumber}: '
        'status ${dispatch.status.name} is terminal',
      );
    }

    final targetVehicle = vehicle ??
        (newStatus == DispatchStatus.delivered && completionOdometer != null
            ? Vehicle(
                id: dispatch.vehicleId,
                name: dispatch.vehicleName,
                plateNumber: dispatch.plateNumber,
                currentOdometer: 0,
                status: VehicleStatus.active,
              )
            : null);

    final result = DispatchService.updateDispatchStatus(
      dispatch: dispatch,
      newStatus: newStatus,
      notes: notes,
      vehicle: targetVehicle,
      completionOdometer: completionOdometer,
    );

    _replaceDispatch(result.dispatch);
    return result;
  }

  /// Cancels a dispatch (shorthand for advanceStatus → cancelled).
  Dispatch cancelDispatch(String dispatchId, {String? reason}) {
    final result = advanceStatus(
      dispatchId: dispatchId,
      newStatus: DispatchStatus.cancelled,
      notes: reason,
    );
    return result.dispatch;
  }

  // ── Reset ─────────────────────────────────────────────────────────────────────

  /// Resets the form to empty while preserving the dispatch list and filter.
  void reset() {
    _state = FleetDispatchState(
      dispatches: _state.dispatches,
      statusFilter: _state.statusFilter,
    );
    _applyFilter();
  }

  // ── Internals ─────────────────────────────────────────────────────────────────

  void _applyFilter() {
    final filter = _state.statusFilter;
    final filtered = filter == null
        ? _state.dispatches
        : List<Dispatch>.unmodifiable(
            _state.dispatches.where((d) {
              if (filter == DispatchStatus.cancelled) {
                return d.status == DispatchStatus.cancelled ||
                    d.status == DispatchStatus.returned;
              }
              return d.status == filter;
            }),
          );
    _state = _state.copyWith(filteredDispatches: filtered);
  }

  Dispatch _findDispatch(String id) {
    try {
      return _state.dispatches.firstWhere((d) => d.id == id);
    } catch (_) {
      throw StateError('Dispatch with id "$id" not found');
    }
  }

  void _replaceDispatch(Dispatch updated) {
    final newList = List<Dispatch>.unmodifiable(
      _state.dispatches.map((d) => d.id == updated.id ? updated : d),
    );
    _state = _state.copyWith(dispatches: newList);
    _applyFilter();
  }
}
