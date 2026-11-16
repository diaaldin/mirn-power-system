import 'package:test/test.dart';
import 'package:sales_logistics_system/features/logistics/domain/models/dispatch.dart';
import 'package:sales_logistics_system/features/logistics/presentation/controllers/fleet_dispatch_controller.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Fully populates the form on [ctrl] with valid values.
  void fillForm(FleetDispatchController ctrl) {
    ctrl.setCustomer(id: 'cust-01', name: 'Al-Quds Contracting', phone: '050-1234567');
    ctrl.setVehicle(id: 'veh-01', name: 'Mercedes Actros', plateNumber: '65-432-10');
    ctrl.setDriver(id: 'drv-01', name: 'Yousef Mansour');
    ctrl.setDeliveryAddress('Beit Hanina, Jerusalem');
    ctrl.setCargoDescription('150 m² Marble + 4 Toilets');
  }

  // ---------------------------------------------------------------------------
  // 1. Initial state
  // ---------------------------------------------------------------------------

  group('FleetDispatchController initial state', () {
    test('dispatches is empty', () {
      final ctrl = FleetDispatchController();
      expect(ctrl.state.dispatches, isEmpty);
    });

    test('filteredDispatches is empty', () {
      final ctrl = FleetDispatchController();
      expect(ctrl.state.filteredDispatches, isEmpty);
    });

    test('statusFilter is null', () {
      final ctrl = FleetDispatchController();
      expect(ctrl.state.statusFilter, isNull);
    });

    test('all form fields are empty / null', () {
      final ctrl = FleetDispatchController();
      final s = ctrl.state;
      expect(s.customerId, equals(''));
      expect(s.customerName, equals(''));
      expect(s.customerPhone, equals(''));
      expect(s.vehicleId, isNull);
      expect(s.vehicleName, isNull);
      expect(s.plateNumber, isNull);
      expect(s.driverId, isNull);
      expect(s.driverName, isNull);
      expect(s.deliveryAddress, equals(''));
      expect(s.cargoDescription, equals(''));
      expect(s.invoiceNumber, isNull);
      expect(s.saleId, isNull);
      expect(s.formNotes, isNull);
      expect(s.isSubmitting, isFalse);
      expect(s.errorMessage, isNull);
      expect(s.lastCreatedDispatch, isNull);
    });

    test('initial list is preserved when passed to constructor', () {
      final now = DateTime(2026, 11, 14);
      final existing = Dispatch(
        id: 'dsp-seed',
        dispatchNumber: 'DSP-2026-00000',
        date: now,
        customerId: 'c1',
        customerName: 'Seed Customer',
        customerPhone: '050-0000000',
        deliveryAddress: 'Seed Address',
        cargoDescription: 'Seed Cargo',
        vehicleId: 'v1',
        vehicleName: 'Truck A',
        plateNumber: '11-111-11',
        driverId: 'd1',
        driverName: 'Driver A',
        status: DispatchStatus.pending,
        updatedAt: now,
      );
      final ctrl = FleetDispatchController(initial: [existing]);
      expect(ctrl.state.dispatches.length, equals(1));
      expect(ctrl.state.dispatches.first.id, equals('dsp-seed'));
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Form setters
  // ---------------------------------------------------------------------------

  group('Form setters', () {
    test('setCustomer updates customerId, customerName, customerPhone', () {
      final ctrl = FleetDispatchController();
      ctrl.setCustomer(id: 'c1', name: 'Haifa Ceramics', phone: '052-9998877');
      expect(ctrl.state.customerId, equals('c1'));
      expect(ctrl.state.customerName, equals('Haifa Ceramics'));
      expect(ctrl.state.customerPhone, equals('052-9998877'));
    });

    test('setVehicle updates vehicleId, vehicleName, plateNumber', () {
      final ctrl = FleetDispatchController();
      ctrl.setVehicle(id: 'v1', name: 'Volvo FH 500', plateNumber: '12-345-67');
      expect(ctrl.state.vehicleId, equals('v1'));
      expect(ctrl.state.vehicleName, equals('Volvo FH 500'));
      expect(ctrl.state.plateNumber, equals('12-345-67'));
    });

    test('setDriver updates driverId and driverName', () {
      final ctrl = FleetDispatchController();
      ctrl.setDriver(id: 'd1', name: 'Ahmad Khalil');
      expect(ctrl.state.driverId, equals('d1'));
      expect(ctrl.state.driverName, equals('Ahmad Khalil'));
    });

    test('setDeliveryAddress updates deliveryAddress', () {
      final ctrl = FleetDispatchController();
      ctrl.setDeliveryAddress('Downtown Haifa');
      expect(ctrl.state.deliveryAddress, equals('Downtown Haifa'));
    });

    test('setCargoDescription updates cargoDescription', () {
      final ctrl = FleetDispatchController();
      ctrl.setCargoDescription('50 Boxes Wall Tiles');
      expect(ctrl.state.cargoDescription, equals('50 Boxes Wall Tiles'));
    });

    test('setInvoiceRef updates saleId and invoiceNumber', () {
      final ctrl = FleetDispatchController();
      ctrl.setInvoiceRef(saleId: 'sale-99', invoiceNumber: 'INV-2026-00099');
      expect(ctrl.state.saleId, equals('sale-99'));
      expect(ctrl.state.invoiceNumber, equals('INV-2026-00099'));
    });

    test('setInvoiceRef with nulls clears saleId and invoiceNumber', () {
      final ctrl = FleetDispatchController();
      ctrl.setInvoiceRef(saleId: 'sale-99', invoiceNumber: 'INV-2026-00099');
      ctrl.setInvoiceRef(saleId: null, invoiceNumber: null);
      expect(ctrl.state.saleId, isNull);
      expect(ctrl.state.invoiceNumber, isNull);
    });

    test('setFormNotes updates formNotes', () {
      final ctrl = FleetDispatchController();
      ctrl.setFormNotes('Deliver after 10 AM');
      expect(ctrl.state.formNotes, equals('Deliver after 10 AM'));
    });

    test('setFormNotes with null clears formNotes', () {
      final ctrl = FleetDispatchController();
      ctrl.setFormNotes('Some note');
      ctrl.setFormNotes(null);
      expect(ctrl.state.formNotes, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. submitNewDispatch – happy path
  // ---------------------------------------------------------------------------

  group('submitNewDispatch success', () {
    test('returns a Dispatch with pending status and correct fields', () {
      final ctrl = FleetDispatchController();
      fillForm(ctrl);
      ctrl.setInvoiceRef(saleId: 'sale-123', invoiceNumber: 'INV-2026-00045');
      ctrl.setFormNotes('Deliver before 2 PM');

      final date = DateTime(2026, 11, 14, 9, 30);
      final dispatch = ctrl.submitNewDispatch(date: date);

      expect(dispatch.status, equals(DispatchStatus.pending));
      expect(dispatch.customerId, equals('cust-01'));
      expect(dispatch.customerName, equals('Al-Quds Contracting'));
      expect(dispatch.vehicleId, equals('veh-01'));
      expect(dispatch.driverId, equals('drv-01'));
      expect(dispatch.deliveryAddress, equals('Beit Hanina, Jerusalem'));
      expect(dispatch.cargoDescription, equals('150 m² Marble + 4 Toilets'));
      expect(dispatch.saleId, equals('sale-123'));
      expect(dispatch.invoiceNumber, equals('INV-2026-00045'));
      expect(dispatch.notes, equals('Deliver before 2 PM'));
    });

    test('dispatches list length increases by 1', () {
      final ctrl = FleetDispatchController();
      fillForm(ctrl);
      ctrl.submitNewDispatch(date: DateTime(2026, 11, 14));
      expect(ctrl.state.dispatches.length, equals(1));
    });

    test('lastCreatedDispatch is set after submit', () {
      final ctrl = FleetDispatchController();
      fillForm(ctrl);
      final dispatch = ctrl.submitNewDispatch(date: DateTime(2026, 11, 14));
      expect(ctrl.state.lastCreatedDispatch, isNotNull);
      expect(ctrl.state.lastCreatedDispatch!.id, equals(dispatch.id));
    });

    test('form fields are reset to empty after submit', () {
      final ctrl = FleetDispatchController();
      fillForm(ctrl);
      ctrl.setInvoiceRef(saleId: 'sale-123', invoiceNumber: 'INV-00045');
      ctrl.setFormNotes('Some note');
      ctrl.submitNewDispatch(date: DateTime(2026, 11, 14));

      final s = ctrl.state;
      expect(s.customerId, equals(''));
      expect(s.customerName, equals(''));
      expect(s.vehicleId, isNull);
      expect(s.driverId, isNull);
      expect(s.deliveryAddress, equals(''));
      expect(s.cargoDescription, equals(''));
      expect(s.saleId, isNull);
      expect(s.invoiceNumber, isNull);
      expect(s.formNotes, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. submitNewDispatch – validation errors
  // ---------------------------------------------------------------------------

  group('submitNewDispatch validation errors', () {
    test('throws ArgumentError when deliveryAddress is blank', () {
      final ctrl = FleetDispatchController();
      ctrl.setCustomer(id: 'c1', name: 'Customer', phone: '050-0000000');
      ctrl.setVehicle(id: 'v1', name: 'Truck', plateNumber: '11-111-11');
      ctrl.setDriver(id: 'd1', name: 'Driver');
      ctrl.setDeliveryAddress('   ');
      ctrl.setCargoDescription('Some cargo');
      expect(
        () => ctrl.submitNewDispatch(date: DateTime(2026, 11, 14)),
        throwsArgumentError,
      );
    });

    test('throws StateError when no vehicle selected', () {
      final ctrl = FleetDispatchController();
      ctrl.setCustomer(id: 'c1', name: 'Customer', phone: '050-0000000');
      ctrl.setDriver(id: 'd1', name: 'Driver');
      ctrl.setDeliveryAddress('Some Address');
      ctrl.setCargoDescription('Some cargo');
      expect(
        () => ctrl.submitNewDispatch(date: DateTime(2026, 11, 14)),
        throwsStateError,
      );
    });

    test('throws StateError when no driver selected', () {
      final ctrl = FleetDispatchController();
      ctrl.setCustomer(id: 'c1', name: 'Customer', phone: '050-0000000');
      ctrl.setVehicle(id: 'v1', name: 'Truck', plateNumber: '11-111-11');
      ctrl.setDeliveryAddress('Some Address');
      ctrl.setCargoDescription('Some cargo');
      expect(
        () => ctrl.submitNewDispatch(date: DateTime(2026, 11, 14)),
        throwsStateError,
      );
    });

    test('throws StateError when no customer selected', () {
      final ctrl = FleetDispatchController();
      ctrl.setVehicle(id: 'v1', name: 'Truck', plateNumber: '11-111-11');
      ctrl.setDriver(id: 'd1', name: 'Driver');
      ctrl.setDeliveryAddress('Some Address');
      ctrl.setCargoDescription('Some cargo');
      expect(
        () => ctrl.submitNewDispatch(date: DateTime(2026, 11, 14)),
        throwsStateError,
      );
    });

    test('StateError message mentions "No vehicle selected" when vehicle missing', () {
      final ctrl = FleetDispatchController();
      ctrl.setCustomer(id: 'c1', name: 'Customer', phone: '050-0000000');
      ctrl.setDriver(id: 'd1', name: 'Driver');
      ctrl.setDeliveryAddress('Some Address');
      ctrl.setCargoDescription('Some cargo');
      expect(
        () => ctrl.submitNewDispatch(date: DateTime(2026, 11, 14)),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', contains('No vehicle selected')),
        ),
      );
    });

    test('StateError message mentions "No driver selected" when driver missing', () {
      final ctrl = FleetDispatchController();
      ctrl.setCustomer(id: 'c1', name: 'Customer', phone: '050-0000000');
      ctrl.setVehicle(id: 'v1', name: 'Truck', plateNumber: '11-111-11');
      ctrl.setDeliveryAddress('Some Address');
      ctrl.setCargoDescription('Some cargo');
      expect(
        () => ctrl.submitNewDispatch(date: DateTime(2026, 11, 14)),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', contains('No driver selected')),
        ),
      );
    });

    test('StateError message mentions "No customer selected" when customer missing', () {
      final ctrl = FleetDispatchController();
      ctrl.setVehicle(id: 'v1', name: 'Truck', plateNumber: '11-111-11');
      ctrl.setDriver(id: 'd1', name: 'Driver');
      ctrl.setDeliveryAddress('Some Address');
      ctrl.setCargoDescription('Some cargo');
      expect(
        () => ctrl.submitNewDispatch(date: DateTime(2026, 11, 14)),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', contains('No customer selected')),
        ),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 5. setStatusFilter
  // ---------------------------------------------------------------------------

  group('setStatusFilter', () {
    late FleetDispatchController ctrl;
    late DateTime baseDate;

    setUp(() {
      baseDate = DateTime(2026, 11, 14);
      ctrl = FleetDispatchController();
    });

    Dispatch _makeDispatch(String id, String num, DispatchStatus status) {
      return Dispatch(
        id: id,
        dispatchNumber: num,
        date: baseDate,
        customerId: 'c1',
        customerName: 'Customer',
        customerPhone: '050-0000000',
        deliveryAddress: 'Address',
        cargoDescription: 'Cargo',
        vehicleId: 'v1',
        vehicleName: 'Truck',
        plateNumber: '11-111-11',
        driverId: 'd1',
        driverName: 'Driver',
        status: status,
        updatedAt: baseDate,
      );
    }

    test('setStatusFilter(pending) shows only pending dispatches', () {
      ctrl = FleetDispatchController(initial: [
        _makeDispatch('d1', 'DSP-2026-00001', DispatchStatus.pending),
        _makeDispatch('d2', 'DSP-2026-00002', DispatchStatus.dispatched),
        _makeDispatch('d3', 'DSP-2026-00003', DispatchStatus.pending),
      ]);
      ctrl.setStatusFilter(DispatchStatus.pending);
      expect(ctrl.state.filteredDispatches.length, equals(2));
      expect(
        ctrl.state.filteredDispatches.every((d) => d.status == DispatchStatus.pending),
        isTrue,
      );
    });

    test('setStatusFilter(null) shows all dispatches', () {
      ctrl = FleetDispatchController(initial: [
        _makeDispatch('d1', 'DSP-2026-00001', DispatchStatus.pending),
        _makeDispatch('d2', 'DSP-2026-00002', DispatchStatus.dispatched),
        _makeDispatch('d3', 'DSP-2026-00003', DispatchStatus.delivered),
      ]);
      ctrl.setStatusFilter(DispatchStatus.pending);
      ctrl.setStatusFilter(null);
      expect(ctrl.state.filteredDispatches.length, equals(3));
      expect(ctrl.state.statusFilter, isNull);
    });

    test('filteredDispatches equals dispatches when filter is null', () {
      ctrl = FleetDispatchController(initial: [
        _makeDispatch('d1', 'DSP-2026-00001', DispatchStatus.pending),
        _makeDispatch('d2', 'DSP-2026-00002', DispatchStatus.delivered),
      ]);
      expect(
        ctrl.state.filteredDispatches.length,
        equals(ctrl.state.dispatches.length),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 6. advanceStatus pending → dispatched
  // ---------------------------------------------------------------------------

  group('advanceStatus', () {
    late FleetDispatchController ctrl;
    late DateTime baseDate;

    setUp(() {
      baseDate = DateTime(2026, 11, 14);
      ctrl = FleetDispatchController();
      // Submit one dispatch
      ctrl.setCustomer(id: 'cust-01', name: 'Al-Quds', phone: '050-1234567');
      ctrl.setVehicle(id: 'veh-01', name: 'Mercedes Actros', plateNumber: '65-432-10');
      ctrl.setDriver(id: 'drv-01', name: 'Yousef Mansour');
      ctrl.setDeliveryAddress('Beit Hanina');
      ctrl.setCargoDescription('150 m² Marble');
      ctrl.submitNewDispatch(date: baseDate);
    });

    test('pending → dispatched transitions successfully', () {
      final dispatchId = ctrl.state.dispatches.first.id;
      final result = ctrl.advanceStatus(
        dispatchId: dispatchId,
        newStatus: DispatchStatus.dispatched,
        notes: 'Driver departed warehouse',
      );
      expect(result.dispatch.status, equals(DispatchStatus.dispatched));
      expect(ctrl.state.dispatches.first.status, equals(DispatchStatus.dispatched));
    });

    // 7. advanceStatus dispatched → delivered with odometer
    test('dispatched → delivered with odometer updates vehicle', () {
      final dispatchId = ctrl.state.dispatches.first.id;
      ctrl.advanceStatus(
        dispatchId: dispatchId,
        newStatus: DispatchStatus.dispatched,
      );
      final result = ctrl.advanceStatus(
        dispatchId: dispatchId,
        newStatus: DispatchStatus.delivered,
        completionOdometer: 500,
      );
      expect(result.dispatch.status, equals(DispatchStatus.delivered));
      expect(result.updatedVehicle, isNotNull);
      expect(result.updatedVehicle!.currentOdometer, equals(500));
    });

    // 8. advanceStatus on terminal state throws
    test('throws StateError when dispatch is in terminal state', () {
      final dispatchId = ctrl.state.dispatches.first.id;
      ctrl.advanceStatus(
        dispatchId: dispatchId,
        newStatus: DispatchStatus.dispatched,
      );
      ctrl.advanceStatus(
        dispatchId: dispatchId,
        newStatus: DispatchStatus.delivered,
      );
      expect(
        () => ctrl.advanceStatus(
          dispatchId: dispatchId,
          newStatus: DispatchStatus.cancelled,
        ),
        throwsStateError,
      );
    });

    test('dispatched → delivered without odometer returns null updatedVehicle', () {
      final dispatchId = ctrl.state.dispatches.first.id;
      ctrl.advanceStatus(
        dispatchId: dispatchId,
        newStatus: DispatchStatus.dispatched,
      );
      final result = ctrl.advanceStatus(
        dispatchId: dispatchId,
        newStatus: DispatchStatus.delivered,
      );
      expect(result.dispatch.status, equals(DispatchStatus.delivered));
      expect(result.updatedVehicle, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 9. cancelDispatch pending
  // ---------------------------------------------------------------------------

  group('cancelDispatch', () {
    late FleetDispatchController ctrl;
    late DateTime baseDate;

    setUp(() {
      baseDate = DateTime(2026, 11, 14);
      ctrl = FleetDispatchController();
      ctrl.setCustomer(id: 'cust-01', name: 'Al-Quds', phone: '050-1234567');
      ctrl.setVehicle(id: 'veh-01', name: 'Mercedes Actros', plateNumber: '65-432-10');
      ctrl.setDriver(id: 'drv-01', name: 'Yousef Mansour');
      ctrl.setDeliveryAddress('Beit Hanina');
      ctrl.setCargoDescription('150 m² Marble');
      ctrl.submitNewDispatch(date: baseDate);
    });

    test('cancelDispatch pending → cancelled', () {
      final dispatchId = ctrl.state.dispatches.first.id;
      final cancelled = ctrl.cancelDispatch(dispatchId, reason: 'Customer changed mind');
      expect(cancelled.status, equals(DispatchStatus.cancelled));
      expect(ctrl.state.dispatches.first.status, equals(DispatchStatus.cancelled));
    });

    // 10. cancelDispatch delivered throws
    test('cancelDispatch on delivered dispatch throws StateError', () {
      final dispatchId = ctrl.state.dispatches.first.id;
      ctrl.advanceStatus(dispatchId: dispatchId, newStatus: DispatchStatus.dispatched);
      ctrl.advanceStatus(dispatchId: dispatchId, newStatus: DispatchStatus.delivered);
      expect(
        () => ctrl.cancelDispatch(dispatchId),
        throwsStateError,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 11. Dispatch number format
  // ---------------------------------------------------------------------------

  group('generateDispatchNumber format', () {
    test('first dispatch number is DSP-YYYY-00001 with 5-digit padding', () {
      final ctrl = FleetDispatchController();
      fillForm(ctrl);
      final date = DateTime(2026, 3, 15);
      final dispatch = ctrl.submitNewDispatch(date: date);
      expect(dispatch.dispatchNumber, equals('DSP-2026-00001'));
    });

    test('dispatch number uses year from provided date', () {
      final ctrl = FleetDispatchController();
      fillForm(ctrl);
      final dispatch = ctrl.submitNewDispatch(date: DateTime(2025, 1, 1));
      expect(dispatch.dispatchNumber, startsWith('DSP-2025-'));
    });
  });

  // ---------------------------------------------------------------------------
  // 12. Multiple dispatches – sequential numbers
  // ---------------------------------------------------------------------------

  group('multiple dispatches sequential numbers', () {
    test('submitting 3 dispatches yields DSP-2026-00001..00003', () {
      final ctrl = FleetDispatchController();
      final date = DateTime(2026, 11, 14);
      final numbers = <String>[];

      for (int i = 0; i < 3; i++) {
        ctrl.setCustomer(id: 'c$i', name: 'Customer $i', phone: '050-000000$i');
        ctrl.setVehicle(id: 'v$i', name: 'Truck $i', plateNumber: '1$i-111-11');
        ctrl.setDriver(id: 'd$i', name: 'Driver $i');
        ctrl.setDeliveryAddress('Address $i');
        ctrl.setCargoDescription('Cargo $i');
        final d = ctrl.submitNewDispatch(date: date);
        numbers.add(d.dispatchNumber);
      }

      expect(numbers, equals(['DSP-2026-00001', 'DSP-2026-00002', 'DSP-2026-00003']));
      expect(ctrl.state.dispatches.length, equals(3));
    });

    test('initialSeq shifts starting number', () {
      final ctrl = FleetDispatchController(initialSeq: 10);
      fillForm(ctrl);
      final dispatch = ctrl.submitNewDispatch(date: DateTime(2026, 11, 14));
      expect(dispatch.dispatchNumber, equals('DSP-2026-00010'));
    });
  });

  // ---------------------------------------------------------------------------
  // 13. reset()
  // ---------------------------------------------------------------------------

  group('reset()', () {
    test('clears form but preserves dispatches and filter', () {
      final ctrl = FleetDispatchController();
      fillForm(ctrl);
      ctrl.submitNewDispatch(date: DateTime(2026, 11, 14));
      ctrl.setStatusFilter(DispatchStatus.pending);

      // Fill form again without submitting
      fillForm(ctrl);
      ctrl.setFormNotes('Pending note');
      ctrl.reset();

      expect(ctrl.state.dispatches.length, equals(1));
      expect(ctrl.state.statusFilter, equals(DispatchStatus.pending));
      expect(ctrl.state.customerId, equals(''));
      expect(ctrl.state.vehicleId, isNull);
      expect(ctrl.state.driverId, isNull);
      expect(ctrl.state.formNotes, isNull);
    });
  });
}
