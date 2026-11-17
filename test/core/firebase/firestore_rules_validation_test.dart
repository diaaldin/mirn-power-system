import 'dart:io';
import 'package:test/test.dart';
import 'package:sales_logistics_system/core/firebase/firestore_schema.dart';

void main() {
  group('Firestore Schema & Path Constants', () {
    test('defines all required business collections', () {
      expect(FirestoreCollections.products, equals('products'));
      expect(FirestoreCollections.contacts, equals('contacts'));
      expect(FirestoreCollections.sales, equals('sales'));
      expect(FirestoreCollections.creditNotes, equals('credit_notes'));
      expect(FirestoreCollections.checks, equals('checks'));
      expect(FirestoreCollections.purchases, equals('purchases'));
      expect(FirestoreCollections.dispatches, equals('dispatches'));
      expect(FirestoreCollections.expenses, equals('expenses'));
      expect(FirestoreCollections.statementEntries, equals('statement_entries'));
      expect(FirestoreCollections.counters, equals('counters'));
      expect(FirestoreCollections.users, equals('users'));
    });

    test('generates expected document paths', () {
      expect(FirestoreCollections.productPath('p1'), equals('products/p1'));
      expect(FirestoreCollections.contactPath('c1'), equals('contacts/c1'));
      expect(FirestoreCollections.salePath('s1'), equals('sales/s1'));
      expect(FirestoreCollections.checkPath('chk1'), equals('checks/chk1'));
    });
  });

  group('Firestore Security Rules File', () {
    test('firestore.rules exists and contains Israeli statutory validation constraints', () {
      final rulesFile = File('firestore.rules');
      expect(rulesFile.existsSync(), isTrue);

      final content = rulesFile.readAsStringSync();
      expect(content, contains('rules_version = \'2\';'));
      expect(content, contains('match /products/{productId}'));
      expect(content, contains('match /contacts/{contactId}'));
      expect(content, contains('match /sales/{saleId}'));
      expect(content, contains('match /checks/{checkId}'));
      expect(content, contains('match /statement_entries/{entryId}'));
      // Immutability rule for statement ledger
      expect(content, contains('allow update, delete: if false;'));
    });

    test('firestore.indexes.json exists and defines required composite queries', () {
      final indexFile = File('firestore.indexes.json');
      expect(indexFile.existsSync(), isTrue);

      final content = indexFile.readAsStringSync();
      expect(content, contains('statement_entries'));
      expect(content, contains('contactId'));
      expect(content, contains('sales'));
    });
  });
}
