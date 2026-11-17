import '../repositories/check_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/dispatch_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/in_memory/in_memory_check_repository.dart';
import '../repositories/in_memory/in_memory_contact_repository.dart';
import '../repositories/in_memory/in_memory_dispatch_repository.dart';
import '../repositories/in_memory/in_memory_expense_repository.dart';
import '../repositories/in_memory/in_memory_product_repository.dart';
import '../repositories/in_memory/in_memory_purchase_repository.dart';
import '../repositories/in_memory/in_memory_sale_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/purchase_repository.dart';
import '../repositories/sale_repository.dart';
import '../../features/checks/domain/services/check_lifecycle_orchestrator.dart';
import '../../features/purchases/domain/services/purchase_transaction_orchestrator.dart';
import '../../features/returns/domain/services/credit_note_transaction_orchestrator.dart';
import '../../features/sales/domain/services/sale_transaction_orchestrator.dart';
import '../../features/inventory/domain/models/product.dart';
import '../../features/accounts/domain/models/contact.dart';
import '../../features/checks/domain/models/check_record.dart';

/// Centralized Service Locator for M.I.R.N POWER Management System.
/// Provides reactive repositories and atomic transaction orchestrators.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  late ProductRepository productRepository;
  late ContactRepository contactRepository;
  late SaleRepository saleRepository;
  late CheckRepository checkRepository;
  late PurchaseRepository purchaseRepository;
  late DispatchRepository dispatchRepository;
  late ExpenseRepository expenseRepository;

  late SaleTransactionOrchestrator saleOrchestrator;
  late PurchaseTransactionOrchestrator purchaseOrchestrator;
  late CreditNoteTransactionOrchestrator creditNoteOrchestrator;
  late CheckLifecycleOrchestrator checkLifecycleOrchestrator;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  void initialize({
    List<Product>? initialProducts,
    List<Contact>? initialContacts,
    List<CheckRecord>? initialChecks,
  }) {
    final prodRepo = InMemoryProductRepository(initialProducts: initialProducts);
    final contRepo = InMemoryContactRepository(initialContacts: initialContacts);
    final saleRepo = InMemorySaleRepository();
    final chkRepo = InMemoryCheckRepository(initialChecks: initialChecks);
    final purchRepo = InMemoryPurchaseRepository();
    final dispRepo = InMemoryDispatchRepository();
    final expRepo = InMemoryExpenseRepository();

    productRepository = prodRepo;
    contactRepository = contRepo;
    saleRepository = saleRepo;
    checkRepository = chkRepo;
    purchaseRepository = purchRepo;
    dispatchRepository = dispRepo;
    expenseRepository = expRepo;

    saleOrchestrator = SaleTransactionOrchestrator(
      productRepository: prodRepo,
      contactRepository: contRepo,
      saleRepository: saleRepo,
      checkRepository: chkRepo,
    );

    purchaseOrchestrator = PurchaseTransactionOrchestrator(
      productRepository: prodRepo,
      contactRepository: contRepo,
      purchaseRepository: purchRepo,
    );

    creditNoteOrchestrator = CreditNoteTransactionOrchestrator(
      productRepository: prodRepo,
      contactRepository: contRepo,
      saleRepository: saleRepo,
    );

    checkLifecycleOrchestrator = CheckLifecycleOrchestrator(
      checkRepository: chkRepo,
      contactRepository: contRepo,
    );

    _isInitialized = true;
  }

  void dispose() {
    if (productRepository is InMemoryProductRepository) {
      (productRepository as InMemoryProductRepository).dispose();
    }
    if (contactRepository is InMemoryContactRepository) {
      (contactRepository as InMemoryContactRepository).dispose();
    }
    if (saleRepository is InMemorySaleRepository) {
      (saleRepository as InMemorySaleRepository).dispose();
    }
    if (checkRepository is InMemoryCheckRepository) {
      (checkRepository as InMemoryCheckRepository).dispose();
    }
    if (purchaseRepository is InMemoryPurchaseRepository) {
      (purchaseRepository as InMemoryPurchaseRepository).dispose();
    }
    if (dispatchRepository is InMemoryDispatchRepository) {
      (dispatchRepository as InMemoryDispatchRepository).dispose();
    }
    if (expenseRepository is InMemoryExpenseRepository) {
      (expenseRepository as InMemoryExpenseRepository).dispose();
    }
    _isInitialized = false;
  }
}
