import 'package:test/test.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/driver.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/vehicle.dart';
import 'package:sales_logistics_system/features/logistics/domain/models/dispatch.dart';
import 'package:sales_logistics_system/features/logistics/domain/services/dispatch_service.dart';

void main() {
  group('DispatchService', () {
    const activeVehicle = Vehicle(
      id: 'veh-001',
      name: 'Mercedes-Benz Actros 1845',
      plateNumber: '65-432-10',
      modelYear: 2022,
      currentOdometer: 150000,
      status: VehicleStatus.active,
    );

    const maintenanceVehicle = Vehicle(
      id: 'veh-002',
      name: 'Volvo FH 500',
      plateNumber: '12-345-67',
      modelYear: 2021,
      currentOdometer: 210000,
      status: VehicleStatus.maintenance,
    );

    const inactiveVehicle = Vehicle(
      id: 'veh-003',
      name: 'Isuzu Forward',
      plateNumber: '99-888-77',
      modelYear: 2018,
      currentOdometer: 320000,
      status: VehicleStatus.inactive,
    );

    const activeDriver = Driver(
      id: 'drv-001',
      fullName: 'Yousef Mansour',
      phone: '052-1234567',
      licenseNumber: 'LIC-987654',
      status: DriverStatus.active,
    );

    const inactiveDriver = Driver(
      id: 'drv-002',
      fullName: 'Ahmad Khalil',
      phone: '054-7654321',
      licenseNumber: 'LIC-112233',
      status: DriverStatus.inactive,
    );

    group('createDispatch', () {
      test('successfully creates a dispatch with pending status and correct fields', () {
        final createDate = DateTime(2026, 11, 14, 9, 30);
        final input = CreateDispatchInput(
          id: 'dsp-custom-001',
          dispatchNumber: 'DSP-2026-00001',
          date: createDate,
          customerId: 'cust-10',
          customerName: 'Al-Quds Contracting',
          customerPhone: '050-1234567',
          deliveryAddress: ' Beit Hanina, Jerusalem ',
          cargoDescription: ' 150 m² Marble + 4 Toilets ',
          vehicle: activeVehicle,
          driver: activeDriver,
          saleId: 'sale-123',
          invoiceNumber: 'INV-2026-00045',
          notes: 'Deliver before 2 PM',
        );

        final dispatch = DispatchService.createDispatch(input);

        expect(dispatch.id, equals('dsp-custom-001'));
        expect(dispatch.dispatchNumber, equals('DSP-2026-00001'));
        expect(dispatch.date, equals(createDate));
        expect(dispatch.customerId, equals('cust-10'));
        expect(dispatch.customerName, equals('Al-Quds Contracting'));
        expect(dispatch.customerPhone, equals('050-1234567'));
        expect(dispatch.deliveryAddress, equals('Beit Hanina, Jerusalem'));
        expect(dispatch.cargoDescription, equals('150 m² Marble + 4 Toilets'));
        expect(dispatch.vehicleId, equals(activeVehicle.id));
        expect(dispatch.vehicleName, equals(activeVehicle.name));
        expect(dispatch.plateNumber, equals(activeVehicle.plateNumber));
        expect(dispatch.driverId, equals(activeDriver.id));
        expect(dispatch.driverName, equals(activeDriver.fullName));
        expect(dispatch.status, equals(DispatchStatus.pending));
        expect(dispatch.saleId, equals('sale-123'));
        expect(dispatch.invoiceNumber, equals('INV-2026-00045'));
        expect(dispatch.notes, equals('Deliver before 2 PM'));
        expect(dispatch.updatedAt, equals(createDate));
      });

      test('falls back to dispatchNumber when id is null', () {
        final input = CreateDispatchInput(
          dispatchNumber: 'DSP-2026-00002',
          date: DateTime(2026, 11, 14),
          customerId: 'cust-11',
          customerName: 'Haifa Ceramics',
          customerPhone: '052-9998877',
          deliveryAddress: 'Downtown Haifa',
          cargoDescription: '50 Boxes Wall Tiles',
          vehicle: activeVehicle,
          driver: activeDriver,
        );

        final dispatch = DispatchService.createDispatch(input);
        expect(dispatch.id, equals('DSP-2026-00002'));
        expect(dispatch.dispatchNumber, equals('DSP-2026-00002'));
        expect(dispatch.status, equals(DispatchStatus.pending));
      });

      test('throws ArgumentError if deliveryAddress is blank or whitespace', () {
        expect(
          () => DispatchService.createDispatch(
            CreateDispatchInput(
              dispatchNumber: 'DSP-2026-00003',
              date: DateTime(2026, 11, 14),
              customerId: 'cust-10',
              customerName: 'Customer',
              customerPhone: '050-1111111',
              deliveryAddress: '   ',
              cargoDescription: 'Cement Bags',
              vehicle: activeVehicle,
              driver: activeDriver,
            ),
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError if cargoDescription is blank or whitespace', () {
        expect(
          () => DispatchService.createDispatch(
            CreateDispatchInput(
              dispatchNumber: 'DSP-2026-00004',
              date: DateTime(2026, 11, 14),
              customerId: 'cust-10',
              customerName: 'Customer',
              customerPhone: '050-1111111',
              deliveryAddress: 'Main St 12',
              cargoDescription: '',
              vehicle: activeVehicle,
              driver: activeDriver,
            ),
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when vehicle is in maintenance', () {
        expect(
          () => DispatchService.createDispatch(
            CreateDispatchInput(
              dispatchNumber: 'DSP-2026-00005',
              date: DateTime(2026, 11, 14),
              customerId: 'cust-10',
              customerName: 'Customer',
              customerPhone: '050-1111111',
              deliveryAddress: 'Main St 12',
              cargoDescription: 'Tiles',
              vehicle: maintenanceVehicle,
              driver: activeDriver,
            ),
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when vehicle is inactive', () {
        expect(
          () => DispatchService.createDispatch(
            CreateDispatchInput(
              dispatchNumber: 'DSP-2026-00006',
              date: DateTime(2026, 11, 14),
              customerId: 'cust-10',
              customerName: 'Customer',
              customerPhone: '050-1111111',
              deliveryAddress: 'Main St 12',
              cargoDescription: 'Tiles',
              vehicle: inactiveVehicle,
              driver: activeDriver,
            ),
          ),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError when driver is inactive', () {
        expect(
          () => DispatchService.createDispatch(
            CreateDispatchInput(
              dispatchNumber: 'DSP-2026-00007',
              date: DateTime(2026, 11, 14),
              customerId: 'cust-10',
              customerName: 'Customer',
              customerPhone: '050-1111111',
              deliveryAddress: 'Main St 12',
              cargoDescription: 'Tiles',
              vehicle: activeVehicle,
              driver: inactiveDriver,
            ),
          ),
          throwsArgumentError,
        );
      });
    });

    group('updateDispatchStatus - Lifecycle State Machine', () {
      late Dispatch pendingDispatch;
      late Dispatch dispatchedDispatch;
      late Dispatch deliveredDispatch;
      late Dispatch cancelledDispatch;
      late Dispatch returnedDispatch;

      setUp(() {
        final now = DateTime(2026, 11, 14, 10, 0);
        pendingDispatch = Dispatch(
          id: 'dsp-001',
          dispatchNumber: 'DSP-2026-00001',
          date: now,
          customerId: 'cust-10',
          customerName: 'Al-Quds Contracting',
          customerPhone: '050-1234567',
          deliveryAddress: 'Beit Hanina, Jerusalem',
          cargoDescription: '150 m² Marble',
          vehicleId: activeVehicle.id,
          vehicleName: activeVehicle.name,
          plateNumber: activeVehicle.plateNumber,
          driverId: activeDriver.id,
          driverName: activeDriver.fullName,
          status: DispatchStatus.pending,
          notes: 'Original note',
          updatedAt: now,
        );

        dispatchedDispatch = pendingDispatch.copyWith(
          status: DispatchStatus.dispatched,
          updatedAt: now.add(const Duration(hours: 1)),
        );

        deliveredDispatch = dispatchedDispatch.copyWith(
          status: DispatchStatus.delivered,
          updatedAt: now.add(const Duration(hours: 3)),
        );

        cancelledDispatch = pendingDispatch.copyWith(
          status: DispatchStatus.cancelled,
          updatedAt: now.add(const Duration(hours: 1)),
        );

        returnedDispatch = dispatchedDispatch.copyWith(
          status: DispatchStatus.returned,
          updatedAt: now.add(const Duration(hours: 4)),
        );
      });

      test('transitions from pending to dispatched', () {
        final updateTime = DateTime(2026, 11, 14, 11, 0);
        final result = DispatchService.updateDispatchStatus(
          dispatch: pendingDispatch,
          newStatus: DispatchStatus.dispatched,
          updatedAt: updateTime,
          notes: 'Driver departed warehouse',
        );

        expect(result.dispatch.status, equals(DispatchStatus.dispatched));
        expect(result.dispatch.notes, equals('Driver departed warehouse'));
        expect(result.dispatch.updatedAt, equals(updateTime));
        expect(result.updatedVehicle, isNull);
      });

      test('transitions from pending to cancelled', () {
        final result = DispatchService.updateDispatchStatus(
          dispatch: pendingDispatch,
          newStatus: DispatchStatus.cancelled,
          notes: 'Cancelled by customer',
        );

        expect(result.dispatch.status, equals(DispatchStatus.cancelled));
        expect(result.dispatch.notes, equals('Cancelled by customer'));
        expect(result.updatedVehicle, isNull);
      });

      test('transitions from dispatched to delivered', () {
        final result = DispatchService.updateDispatchStatus(
          dispatch: dispatchedDispatch,
          newStatus: DispatchStatus.delivered,
        );

        expect(result.dispatch.status, equals(DispatchStatus.delivered));
        expect(result.dispatch.notes, equals('Original note')); // preserves notes when null
        expect(result.updatedVehicle, isNull);
      });

      test('transitions from dispatched to returned', () {
        final result = DispatchService.updateDispatchStatus(
          dispatch: dispatchedDispatch,
          newStatus: DispatchStatus.returned,
          notes: 'Customer rejected cargo - damage in transit',
        );

        expect(result.dispatch.status, equals(DispatchStatus.returned));
        expect(result.dispatch.notes, equals('Customer rejected cargo - damage in transit'));
        expect(result.updatedVehicle, isNull);
      });

      test('transitions from dispatched to cancelled', () {
        final result = DispatchService.updateDispatchStatus(
          dispatch: dispatchedDispatch,
          newStatus: DispatchStatus.cancelled,
          notes: 'Truck broke down, recall dispatch',
        );

        expect(result.dispatch.status, equals(DispatchStatus.cancelled));
        expect(result.updatedVehicle, isNull);
      });

      group('invalid transitions from non-terminal states', () {
        test('pending cannot transition directly to delivered', () {
          expect(
            () => DispatchService.updateDispatchStatus(
              dispatch: pendingDispatch,
              newStatus: DispatchStatus.delivered,
            ),
            throwsStateError,
          );
        });

        test('pending cannot transition directly to returned', () {
          expect(
            () => DispatchService.updateDispatchStatus(
              dispatch: pendingDispatch,
              newStatus: DispatchStatus.returned,
            ),
            throwsStateError,
          );
        });

        test('pending cannot transition to pending', () {
          expect(
            () => DispatchService.updateDispatchStatus(
              dispatch: pendingDispatch,
              newStatus: DispatchStatus.pending,
            ),
            throwsStateError,
          );
        });

        test('dispatched cannot transition back to pending', () {
          expect(
            () => DispatchService.updateDispatchStatus(
              dispatch: dispatchedDispatch,
              newStatus: DispatchStatus.pending,
            ),
            throwsStateError,
          );
        });

        test('dispatched cannot transition to dispatched', () {
          expect(
            () => DispatchService.updateDispatchStatus(
              dispatch: dispatchedDispatch,
              newStatus: DispatchStatus.dispatched,
            ),
            throwsStateError,
          );
        });
      });

      group('terminal states enforcement', () {
        test('delivered is terminal and rejects any transition', () {
          for (final target in DispatchStatus.values) {
            expect(
              () => DispatchService.updateDispatchStatus(
                dispatch: deliveredDispatch,
                newStatus: target,
              ),
              throwsStateError,
            );
          }
        });

        test('cancelled is terminal and rejects any transition', () {
          for (final target in DispatchStatus.values) {
            expect(
              () => DispatchService.updateDispatchStatus(
                dispatch: cancelledDispatch,
                newStatus: target,
              ),
              throwsStateError,
            );
          }
        });

        test('returned is terminal and rejects any transition', () {
          for (final target in DispatchStatus.values) {
            expect(
              () => DispatchService.updateDispatchStatus(
                dispatch: returnedDispatch,
                newStatus: target,
              ),
              throwsStateError,
            );
          }
        });
      });

      group('odometer and vehicle tracking on delivery', () {
        test('updates vehicle odometer when transitioning to delivered with valid completionOdometer', () {
          const currentKm = 150000;
          const endKm = 150240;
          final vehicle = activeVehicle.copyWith(currentOdometer: currentKm);

          final result = DispatchService.updateDispatchStatus(
            dispatch: dispatchedDispatch,
            newStatus: DispatchStatus.delivered,
            vehicle: vehicle,
            completionOdometer: endKm,
          );

          expect(result.dispatch.status, equals(DispatchStatus.delivered));
          expect(result.updatedVehicle, isNotNull);
          expect(result.updatedVehicle!.currentOdometer, equals(endKm));
        });

        test('allows equal completionOdometer (0 km trip) on delivery', () {
          final result = DispatchService.updateDispatchStatus(
            dispatch: dispatchedDispatch,
            newStatus: DispatchStatus.delivered,
            vehicle: activeVehicle,
            completionOdometer: activeVehicle.currentOdometer,
          );

          expect(result.updatedVehicle, isNotNull);
          expect(result.updatedVehicle!.currentOdometer, equals(activeVehicle.currentOdometer));
        });

        test('throws ArgumentError when completionOdometer is strictly lower than vehicle currentOdometer', () {
          expect(
            () => DispatchService.updateDispatchStatus(
              dispatch: dispatchedDispatch,
              newStatus: DispatchStatus.delivered,
              vehicle: activeVehicle,
              completionOdometer: activeVehicle.currentOdometer - 10,
            ),
            throwsArgumentError,
          );
        });

        test('does not update vehicle when transitioning to non-delivered status even if odometer provided', () {
          final result = DispatchService.updateDispatchStatus(
            dispatch: dispatchedDispatch,
            newStatus: DispatchStatus.returned,
            vehicle: activeVehicle,
            completionOdometer: activeVehicle.currentOdometer + 50,
          );

          expect(result.dispatch.status, equals(DispatchStatus.returned));
          expect(result.updatedVehicle, isNull);
        });
      });

      group('canTransition & isTerminal helper methods', () {
        test('canTransition accurately reports valid and invalid transitions', () {
          expect(DispatchService.canTransition(DispatchStatus.pending, DispatchStatus.dispatched), isTrue);
          expect(DispatchService.canTransition(DispatchStatus.pending, DispatchStatus.cancelled), isTrue);
          expect(DispatchService.canTransition(DispatchStatus.pending, DispatchStatus.delivered), isFalse);
          expect(DispatchService.canTransition(DispatchStatus.pending, DispatchStatus.returned), isFalse);

          expect(DispatchService.canTransition(DispatchStatus.dispatched, DispatchStatus.delivered), isTrue);
          expect(DispatchService.canTransition(DispatchStatus.dispatched, DispatchStatus.returned), isTrue);
          expect(DispatchService.canTransition(DispatchStatus.dispatched, DispatchStatus.cancelled), isTrue);
          expect(DispatchService.canTransition(DispatchStatus.dispatched, DispatchStatus.pending), isFalse);

          expect(DispatchService.canTransition(DispatchStatus.delivered, DispatchStatus.delivered), isFalse);
          expect(DispatchService.canTransition(DispatchStatus.cancelled, DispatchStatus.pending), isFalse);
          expect(DispatchService.canTransition(DispatchStatus.returned, DispatchStatus.dispatched), isFalse);
        });

        test('isTerminal correctly identifies terminal states', () {
          expect(DispatchService.isTerminal(DispatchStatus.delivered), isTrue);
          expect(DispatchService.isTerminal(DispatchStatus.returned), isTrue);
          expect(DispatchService.isTerminal(DispatchStatus.cancelled), isTrue);
          expect(DispatchService.isTerminal(DispatchStatus.pending), isFalse);
          expect(DispatchService.isTerminal(DispatchStatus.dispatched), isFalse);
        });
      });
    });
  });
}
