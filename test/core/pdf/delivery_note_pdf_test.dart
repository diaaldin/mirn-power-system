import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:sales_logistics_system/core/pdf/delivery_note_pdf_generator.dart';
import 'package:sales_logistics_system/core/pdf/invoice_pdf_generator.dart';
import 'package:sales_logistics_system/features/logistics/domain/models/dispatch.dart';

void main() {
  group('DeliveryNotePdfGenerator Tests', () {
    const testCompany = CompanyInfo(
      name: 'M.I.R.N POWER',
      nameHebrew: 'מ.י.ר.נ. פאוור',
      nameArabic: 'م.ي.ر.ن. باور',
      subtitleHebrew: 'כלים סניטריים, שיש, אבן והובלה',
      subtitleArabic: 'أدوات صحية، رخام، حجر، ونقل وشحن',
      taxId: '515123456',
      phone: '02-123-4567',
      address: 'ירושלים / القدس',
    );

    final testDispatch = Dispatch(
      id: 'dsp-001',
      dispatchNumber: 'DSP-2026-00001',
      date: DateTime(2026, 11, 14),
      invoiceNumber: 'INV-2026-00042',
      customerId: 'cust-001',
      customerName: 'Ahmad Al-Khalidi / אחמד אל-ח׳אלידי',
      customerPhone: '052-123-4567',
      deliveryAddress: 'רח׳ יפו 12, ירושלים / شارع يافا 12، القدس',
      cargoDescription: 'רצפת שיש קלקטה גולד 60x60 (12 קופסאות) / بلاط رخام كلكتا جولد',
      vehicleId: 'veh-001',
      vehicleName: 'מרצדס ספרינטר לבן',
      plateNumber: '12-345-67',
      driverId: 'drv-001',
      driverName: 'יוסף חמדאן / يوسف حمدان',
      status: DispatchStatus.delivered,
      updatedAt: DateTime(2026, 11, 14, 15, 30),
    );

    test('generates non-empty PDF bytes', () async {
      final Uint8List bytes = await DeliveryNotePdfGenerator.generate(
        dispatch: testDispatch,
        company: testCompany,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
      expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
    });

    test('generates PDF with delivery fee', () async {
      final Uint8List bytes = await DeliveryNotePdfGenerator.generate(
        dispatch: testDispatch,
        company: testCompany,
        deliveryFee: 350.0,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('generates PDF without delivery fee (N/A)', () async {
      final Uint8List bytes = await DeliveryNotePdfGenerator.generate(
        dispatch: testDispatch,
        company: testCompany,
        // deliveryFee omitted → N/A
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('generates PDF with linked invoice reference', () async {
      final dispatchWithInvoice = Dispatch(
        id: 'dsp-002',
        dispatchNumber: 'DSP-2026-00002',
        date: DateTime(2026, 11, 15),
        invoiceNumber: 'INV-2026-00042',
        customerId: 'cust-002',
        customerName: 'Test Customer',
        customerPhone: '050-987-6543',
        deliveryAddress: 'Test Address, City',
        cargoDescription: 'Test Cargo',
        vehicleId: 'veh-002',
        vehicleName: 'Test Vehicle',
        plateNumber: '99-999-99',
        driverId: 'drv-002',
        driverName: 'Test Driver',
        status: DispatchStatus.dispatched,
        updatedAt: DateTime(2026, 11, 15, 10, 0),
      );

      final Uint8List bytes = await DeliveryNotePdfGenerator.generate(
        dispatch: dispatchWithInvoice,
        company: testCompany,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('generates PDF without linked invoice (N/A)', () async {
      final dispatchNoInvoice = Dispatch(
        id: 'dsp-003',
        dispatchNumber: 'DSP-2026-00003',
        date: DateTime(2026, 11, 16),
        invoiceNumber: null,
        customerId: 'cust-003',
        customerName: 'Walk-in Customer',
        customerPhone: '054-111-2222',
        deliveryAddress: 'Some Street 5, Jerusalem',
        cargoDescription: 'Misc goods',
        vehicleId: 'veh-001',
        vehicleName: 'מרצדס ספרינטר לבן',
        plateNumber: '12-345-67',
        driverId: 'drv-001',
        driverName: 'יוסף חמדאן',
        status: DispatchStatus.pending,
        updatedAt: DateTime(2026, 11, 16, 9, 0),
      );

      final Uint8List bytes = await DeliveryNotePdfGenerator.generate(
        dispatch: dispatchNoInvoice,
        company: testCompany,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('handles all dispatch statuses', () async {
      for (final status in DispatchStatus.values) {
        final dispatch = Dispatch(
          id: 'dsp-status-${status.name}',
          dispatchNumber: 'DSP-2026-STATUS-${status.name.toUpperCase()}',
          date: DateTime(2026, 11, 14),
          invoiceNumber: null,
          customerId: 'cust-001',
          customerName: 'Status Test Customer',
          customerPhone: '050-000-0000',
          deliveryAddress: 'Status Test Address',
          cargoDescription: 'Status test cargo for ${status.hebrewLabel}',
          vehicleId: 'veh-001',
          vehicleName: 'Test Vehicle',
          plateNumber: '00-000-00',
          driverId: 'drv-001',
          driverName: 'Test Driver',
          status: status,
          updatedAt: DateTime(2026, 11, 14),
        );

        final Uint8List bytes = await DeliveryNotePdfGenerator.generate(
          dispatch: dispatch,
          company: testCompany,
        );

        expect(bytes, isNotEmpty,
            reason: 'PDF should be non-empty for status: ${status.name}');
        expect(bytes.length, greaterThan(100),
            reason: 'PDF bytes should exceed 100 for status: ${status.name}');
      }
    });
  });
}
