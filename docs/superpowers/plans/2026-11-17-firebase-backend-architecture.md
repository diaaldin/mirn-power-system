# Firebase Backend & Repository Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to execute this plan inline task-by-task.

**Goal:** Build the complete Firebase Backend & Clean Repository Architecture for the M.I.R.N POWER Management System, including abstract repository contracts, in-memory reactive test doubles, atomic multi-document transaction orchestrators, serialization mappers, and production-grade Cloud Firestore security rules (`firestore.rules`).

**Architecture:** Pure Dart abstract repository interfaces decouple domain services and presentation controllers from Firestore. In-memory implementations provide reactive streams (`BehaviorSubject` or broadcast `StreamController`) and atomic state transitions for blazing-fast unit testing. Atomic transaction orchestrators ensure ACID compliance across sales checkouts, purchases, check clearing, and ledger updates. Production-grade `firestore.rules` enforce Israeli statutory invariants, tax ID matching, and debt balance immutability.

**Tech Stack:** Dart 3.x, Flutter 3.x, Cloud Firestore conventions, Stream-based reactive architecture, Pure Dart testing (`test` package).

---

### Global Constraints & Invariants
1. **Zero Breaking Changes**: Existing 291 unit & integration tests must remain 100% green without requiring live network access or native platform channels.
2. **Atomic Integrity**: Cross-document mutations (e.g. Sale -> Product stock decrement + Customer balance increment + Check record creation + Sequence counter increment) must execute atomically.
3. **Statutory Israeli Validation**: All schema and security rules must validate VAT 17%, tax ID `515892104`, sequential numbering format, and non-negative stock counts.
4. **Reactive Streams**: All repository query methods must expose live reactive `Stream<List<T>>` to support real-time UI synchronicity.

---

### Task 1: Core Repository Interfaces & Domain Contracts

**Files:**
- Create: `lib/core/repositories/product_repository.dart`
- Create: `lib/core/repositories/contact_repository.dart`
- Create: `lib/core/repositories/sale_repository.dart`
- Create: `lib/core/repositories/check_repository.dart`
- Create: `lib/core/repositories/purchase_repository.dart`
- Create: `lib/core/repositories/dispatch_repository.dart`
- Create: `lib/core/repositories/expense_repository.dart`
- Test: `test/core/repositories/repository_contracts_test.dart`

- [ ] **Step 1: Write tests for repository interface contracts and mock behaviors**
- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement abstract repository classes in `lib/core/repositories/`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 1**

---

### Task 2: Reactive In-Memory Repository Implementations & Transaction Doubles

**Files:**
- Create: `lib/core/repositories/in_memory/in_memory_product_repository.dart`
- Create: `lib/core/repositories/in_memory/in_memory_contact_repository.dart`
- Create: `lib/core/repositories/in_memory/in_memory_sale_repository.dart`
- Create: `lib/core/repositories/in_memory/in_memory_check_repository.dart`
- Create: `lib/core/repositories/in_memory/in_memory_purchase_repository.dart`
- Create: `lib/core/repositories/in_memory/in_memory_dispatch_repository.dart`
- Create: `lib/core/repositories/in_memory/in_memory_expense_repository.dart`
- Test: `test/core/repositories/in_memory_repositories_test.dart`

- [ ] **Step 1: Write comprehensive reactive stream and mutation tests for in-memory repositories**
- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement in-memory repositories with broadcast stream controllers and snapshot isolation**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 2**

---

### Task 3: Atomic Transaction Orchestrators

**Files:**
- Create: `lib/features/sales/domain/services/sale_transaction_orchestrator.dart`
- Create: `lib/features/purchases/domain/services/purchase_transaction_orchestrator.dart`
- Create: `lib/features/returns/domain/services/credit_note_transaction_orchestrator.dart`
- Create: `lib/features/checks/domain/services/check_lifecycle_orchestrator.dart`
- Test: `test/core/transactions/transaction_orchestrators_test.dart`

- [ ] **Step 1: Write failing tests for atomic transaction rollbacks and success commits**
- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement transaction orchestrators coordinating stock, balances, checks, and sequence counters**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 3**

---

### Task 4: Cloud Firestore Security Rules & Schema Mapping

**Files:**
- Create: `firestore.rules`
- Create: `firestore.indexes.json`
- Create: `lib/core/firebase/firestore_schema.dart`
- Test: `test/core/firebase/firestore_rules_validation_test.dart`

- [ ] **Step 1: Write validation tests for Firestore document schemas and statutory rules constraints**
- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Create `firestore.rules` and `firestore_schema.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 4**

---

### Task 5: Whole-Branch Senior Code Review & Master Integration

- [ ] **Step 1: Run complete test suite (291 existing + new repository tests)**
- [ ] **Step 2: Dispatch Senior Code Reviewer on Pro model**
- [ ] **Step 3: Address any findings**
- [ ] **Step 4: Merge `feat/firebase-backend-architecture` into `master`**
