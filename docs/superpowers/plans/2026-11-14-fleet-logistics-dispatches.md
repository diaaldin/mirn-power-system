# Fleet Logistics, Dispatches & A4 Delivery Notes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Fleet Logistics, Dispatches, and Israeli standard A4 Delivery Note (תעודת משלוח והובלה / سند إرسالية ونقل) module with vehicle/driver dispatching, delivery status lifecycle tracking, odometer logging, and interactive fleet operations UI.

**Architecture:** Pure Dart domain models and services decouple dispatch orchestration and status transitions from the presentation layer. `DispatchService` manages dispatch validation, status progression (`pending` $\rightarrow$ `dispatched` $\rightarrow$ `delivered`), and vehicle odometer updates. `DeliveryNotePdfGenerator` produces statutory Israeli A4 Delivery Notes (תעודת משלוח). A reactive `FleetDispatchController` coordinates state for the Flutter UI and interactive HTML prototype.

**Tech Stack:** Dart 3.x, Flutter 3.x, `pdf` package, `intl`, `test`.

**Spec:** `docs/superpowers/specs/2026-11-13-sales-accounting-logistics-design.md` (Section 2.1 #8 & #9, Section 4.6, Section 4.7, Section 5.5)

## Global Constraints
- Sequential Numbering: Dispatches follow `DSP-YYYY-xxxxx` (e.g. `DSP-2026-00001`).
- Status Flow: `pending` $\rightarrow$ `dispatched` $\rightarrow$ `delivered` (or `cancelled` / `returned`). Invalid state reversions must be rejected.
- Operational Integrity: Inactive vehicles (`VehicleStatus.inactive` or `VehicleStatus.maintenance`) or inactive drivers (`DriverStatus.inactive`) cannot be assigned to new dispatches without validation error.
- Odometer Monotonicity: Upon delivery completion, the recorded odometer reading cannot be less than the vehicle's `currentOdometer`.
- Trilingual Support: Arabic (default RTL), Hebrew (official statutory RTL), English (LTR).
- PDF Documents: Standard A4 format with M.I.R.N POWER luxury branding, Hebrew & Arabic legal headers, cargo breakdown, driver/vehicle details, and dual signature blocks.

## Review Focus
- Invalid dispatch state transitions (e.g. attempting to jump from `delivered` back to `pending`).
- Assigning inactive/maintenance vehicles or inactive drivers.
- Odometer backward drift (completion odometer less than current vehicle odometer).
- Null or blank delivery addresses and cargo descriptions.
- Memory safety: clean disposal of text editing controllers in dispatch dialogs.

---

### Task 1: `DispatchService` Domain Service & Lifecycle State Machine

**Files:**
- Create: `lib/features/logistics/domain/services/dispatch_service.dart`
- Test: `test/features/logistics/dispatch_service_test.dart`

**Interfaces:**
- Consumes: `Dispatch`, `DispatchStatus`, `Vehicle`, `VehicleStatus`, `Driver`, `DriverStatus`, `Contact`.
- Produces: `DispatchService`, `CreateDispatchInput`, `UpdateDispatchStatusResult`.

- [ ] **Step 1: Write failing tests for `DispatchService`**

```dart
// test/features/logistics/dispatch_service_test.dart
import 'package:test/test.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/vehicle.dart';
import 'package:sales_logistics_system/features/fleet/domain/models/driver.dart';
import 'package:sales_logistics_system/features/logistics/domain/models/dispatch.dart';
import 'package:sales_logistics_system/features/logistics/domain/services/dispatch_service.dart';

void main() {
  group('DispatchService Tests', () {
    late Vehicle activeTruck;
    late Driver activeDriver;

    setUp(() {
      activeTruck = const Vehicle(
        id: 'veh-01',
        name: 'Mercedes Actros 3340',
        plateNumber: '72-491-88',
        currentOdometer: 142500,
        status: VehicleStatus.active,
      );

      activeDriver = const Driver(
        id: 'drv-01',
        fullName: 'محمود عيسى',
        phone: '052-9876543',
        licenseNumber: 'LIC-88192',
        status: DriverStatus.active,
      );
    });

    test('creates valid dispatch order with sequential identifier', () {
      final input = CreateDispatchInput(
        dispatchNumber: 'DSP-2026-00001',
        date: DateTime(2026, 11, 14, 10, 0),
        customerId: 'cust-101',
        customerName: 'شركة البراق للمقاولات',
        customerPhone: '052-1234567',
        deliveryAddress: 'رام الله - حي الماصيون / רמאללה',
        cargoDescription: '150 م² رخام كرارا + 4 كراسي حمام جروهي',
        vehicle: activeTruck,
        driver: activeDriver,
        saleId: 'sale-001',
        invoiceNumber: 'INV-2026-00412',
      );

      final dispatch = DispatchService.createDispatch(input: input);

      expect(dispatch.dispatchNumber, equals('DSP-2026-00001'));
      expect(dispatch.status, equals(DispatchStatus.pending));
      expect(dispatch.vehicleId, equals('veh-01'));
      expect(dispatch.driverName, equals('محمود عيسى'));
    });

    test('rejects vehicle in maintenance or inactive status', () {
      final maintenanceTruck = activeTruck.copyWith(status: VehicleStatus.maintenance);

      final input = CreateDispatchInput(
        dispatchNumber: 'DSP-2026-00002',
        date: DateTime(2026, 11, 14),
        customerId: 'cust-101',
        customerName: 'شركة البراق',
        customerPhone: '052',
        deliveryAddress: 'القدس',
        cargoDescription: 'حمولة حجر',
        vehicle: maintenanceTruck,
        driver: activeDriver,
      );

      expect(() => DispatchService.createDispatch(input: input), throwsArgumentError);
    });

    test('transitions from pending -> dispatched -> delivered and updates vehicle odometer', () {
      final input = CreateDispatchInput(
        dispatchNumber: 'DSP-2026-00003',
        date: DateTime(2026, 11, 14),
        customerId: 'cust-101',
        customerName: 'شركة البراق',
        customerPhone: '052',
        deliveryAddress: 'القدس',
        cargoDescription: 'حمولة حجر',
        vehicle: activeTruck,
        driver: activeDriver,
      );

      final dispatch = DispatchService.createDispatch(input: input);

      // 1. Dispatch
      final res1 = DispatchService.updateDispatchStatus(
        dispatch: dispatch,
        newStatus: DispatchStatus.dispatched,
      );
      expect(res1.dispatch.status, equals(DispatchStatus.dispatched));

      // 2. Deliver with odometer update
      final res2 = DispatchService.updateDispatchStatus(
        dispatch: res1.dispatch,
        newStatus: DispatchStatus.delivered,
        vehicle: activeTruck,
        completionOdometer: 142620, // +120 km run
      );
      expect(res2.dispatch.status, equals(DispatchStatus.delivered));
      expect(res2.updatedVehicle?.currentOdometer, equals(142620));
    });

    test('rejects completion odometer lower than current vehicle odometer', () {
      final input = CreateDispatchInput(
        dispatchNumber: 'DSP-2026-00004',
        date: DateTime(2026, 11, 14),
        customerId: 'cust-101',
        customerName: 'شركة البراق',
        customerPhone: '052',
        deliveryAddress: 'القدس',
        cargoDescription: 'حمولة حجر',
        vehicle: activeTruck,
        driver: activeDriver,
      );

      final dispatch = DispatchService.createDispatch(input: input);

      expect(
        () => DispatchService.updateDispatchStatus(
          dispatch: dispatch,
          newStatus: DispatchStatus.delivered,
          vehicle: activeTruck,
          completionOdometer: 140000, // Lower than 142500!
        ),
        throwsArgumentError,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement `DispatchService` in `lib/features/logistics/domain/services/dispatch_service.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 1**

---

### Task 2: Statutory Israeli A4 Delivery Note PDF Generator (`DeliveryNotePdfGenerator`)

**Files:**
- Create: `lib/core/pdf/delivery_note_pdf_generator.dart`
- Test: `test/core/pdf/delivery_note_pdf_test.dart`

**Interfaces:**
- Consumes: `Dispatch`, `CompanyInfo`, `Vehicle`, `Driver`.
- Produces: `DeliveryNotePdfGenerator.generate(Dispatch dispatch, CompanyInfo company, ...) -> Future<Uint8List>`.

- [ ] **Step 1: Write failing test for `DeliveryNotePdfGenerator`**

```dart
// test/core/pdf/delivery_note_pdf_test.dart
import 'package:test/test.dart';
import 'package:sales_logistics_system/features/logistics/domain/models/dispatch.dart';
import 'package:sales_logistics_system/core/pdf/invoice_pdf_generator.dart';
import 'package:sales_logistics_system/core/pdf/delivery_note_pdf_generator.dart';

void main() {
  group('DeliveryNotePdfGenerator Tests', () {
    test('generates valid Israeli standard A4 Delivery Note PDF bytes with dual signatures', () async {
      final dispatch = Dispatch(
        id: 'dsp-001',
        dispatchNumber: 'DSP-2026-00001',
        date: DateTime(2026, 11, 14, 11, 0),
        saleId: 'sale-001',
        invoiceNumber: 'INV-2026-00412',
        customerId: 'cust-101',
        customerName: 'شركة البراق للمقاولات العامة / חברת אל-בוראק',
        customerPhone: '052-1234567',
        deliveryAddress: 'رام الله - الماصيون / רמאללה',
        cargoDescription: '150 מ"ר שיש קררה + 10 ארגזים קרמיקה + 4 אסלות גרואה',
        vehicleId: 'veh-01',
        vehicleName: 'מרסדס אקטרוס 3340 (משאית פול-טריילר)',
        plateNumber: '72-491-88',
        driverId: 'drv-01',
        driverName: 'מחמוד עאסי / محمود عيسى',
        status: DispatchStatus.dispatched,
        notes: 'توصيل للموقع - الطابق الأرضي',
        updatedAt: DateTime(2026, 11, 14),
      );

      const company = CompanyInfo(
        name: 'M.I.R.N POWER',
        nameHebrew: 'מ.י.ר.ן פאוור בע"מ',
        nameArabic: 'شركة إم آي آر إن باور م.ض',
        subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
        subtitleArabic: 'أدوات صحية، رخام، حجر، ونقل وشحن',
        taxId: '516894220',
        phone: '02-5819000',
        address: 'ירושלים / القدس - עטרות',
      );

      final pdfBytes = await DeliveryNotePdfGenerator.generate(
        dispatch: dispatch,
        company: company,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      expect(pdfBytes[0], equals(0x25)); // %
      expect(pdfBytes[1], equals(0x50)); // P
      expect(pdfBytes[2], equals(0x44)); // D
      expect(pdfBytes[3], equals(0x46)); // F
      expect(pdfBytes[4], equals(0x2D)); // -
    });
  });
}
```

- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement `DeliveryNotePdfGenerator` in `lib/core/pdf/delivery_note_pdf_generator.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 2**

---

### Task 3: Presentation Controller & State Machine (`FleetDispatchController`)

**Files:**
- Create: `lib/features/logistics/presentation/controllers/fleet_dispatch_controller.dart`
- Test: `test/features/logistics/fleet_dispatch_controller_test.dart`

**Interfaces:**
- Consumes: `Dispatch`, `DispatchService`, `Vehicle`, `Driver`.
- Produces: `FleetDispatchController`, `FleetDispatchState`.

- [ ] **Step 1: Write failing tests for `FleetDispatchController`**
- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement `FleetDispatchController` in `lib/features/logistics/presentation/controllers/fleet_dispatch_controller.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 3**

---

### Task 4: Interactive Fleet & Dispatches UI in `lib/main.dart` & `mirn_system_preview.html`

**Files:**
- Modify: `lib/main.dart`
- Modify: `mirn_system_preview.html`

**Changes:**
- Update `_buildFleetScreen()` in `lib/main.dart`:
  - Fleet KPI banner: Active Trucks, Total Fleet KMs, Ongoing Dispatches, Active Drivers.
  - Trucks Directory: Live status chips, plate numbers, current odometer, cost/km, and assigned driver.
  - Dispatches List / Kanban with status filter pills (`all`, `pending`, `dispatched`, `delivered`).
  - Action button "أمر إرسالية ونقل جديد / תעודת משלוח חדשה" opening `_showNewDispatchDialog()`:
    - Customer selector, address input, cargo description input, vehicle picker, driver picker, and invoice link.
    - Status advancement triggers (`ابدأ النقل`, `تم التسليم`).
    - 1-click A4 Delivery Note PDF print preview via `DeliveryNotePdfGenerator.generate`.
    - Proper controller lifecycle management (`.whenComplete(...)`).
- Update `mirn_system_preview.html`:
  - Enhance `#view-fleet` with interactive dispatch status updating, new dispatch creation modal, and simulated Delivery Note PDF preview.
- Run complete test suite and verify 100% green.
- Commit with message: `feat(ui): integrate fleet dispatches and delivery note preview into main UI`

- [ ] **Step 1: Implement UI in `lib/main.dart`**
- [ ] **Step 2: Update `mirn_system_preview.html`**
- [ ] **Step 3: Run full test suite**
- [ ] **Step 4: Commit Task 4**

---

### Task 5: Whole-Branch Verification & Senior Code Review

- [ ] **Step 1: Dispatch Senior Code Reviewer on Pro model to audit the complete branch changes**
- [ ] **Step 2: Address any findings**
- [ ] **Step 3: Merge `feat/fleet-logistics-dispatches` into `master` locally using `finishing-a-development-branch`**
- [ ] **Step 4: Confirm master working tree clean and all tests green**
