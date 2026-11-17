# Fleet Expenses, Operating Cost/KM & Expense Vouchers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Fleet Expenses, Cost-Per-Kilometer Analytics, and Israeli Statutory A4 Expense Voucher (שובר תשלום והוצאה / سند صرف ومصروفات) module with vehicle/driver cost attribution, fuel & maintenance metrics, and interactive Flutter & HTML UI.

**Architecture:** Pure Dart domain models and services decouple expense validation, category aggregation, and cost-per-km calculations from the presentation layer. `ExpenseService` manages validation, sequential `EXP-YYYY-xxxxx` numbering, category filtering, and vehicle/fleet operational metrics. `ExpensePdfGenerator` produces statutory Israeli A4 Expense Vouchers. A reactive `ExpensesController` coordinates state for the Flutter UI and interactive HTML prototype.

**Tech Stack:** Dart 3.x, Flutter 3.x, `pdf` package, `intl`, `test`.

**Spec:** `docs/superpowers/specs/2026-11-13-sales-accounting-logistics-design.md` (Section 2.1 #9, Section 4.8, Section 5.5)

## Global Constraints
- Sequential Numbering: Expenses follow `EXP-YYYY-xxxxx` (e.g. `EXP-2026-00001`).
- Validation: Expense amount must be strictly positive (`amount > 0`). Empty descriptions are rejected.
- Vehicle Cost Attribution: When an expense tags a vehicle and provides an odometer reading, the reading cannot be less than the vehicle's `currentOdometer`.
- Cost-Per-KM Engine: Cost/km = Total Vehicle Expenses / Traveled KM. Must guard against division by zero (returns `0.0` if `traveledKm <= 0`).
- Trilingual Support: Arabic (default RTL), Hebrew (official statutory RTL), English (LTR).
- PDF Documents: Standard A4 format with M.I.R.N POWER luxury branding, Hebrew & Arabic legal headers, expense breakdown, vehicle/driver attribution, and dual signature blocks.

## Review Focus
- Division by zero or negative distance in cost/km calculations.
- Backward odometer readings on vehicle-tagged expenses.
- Negative or zero expense amounts bypassing validation.
- Missing category tags or empty descriptions.
- Memory safety: clean disposal of text editing controllers in expense dialogs.

---

### Task 1: `ExpenseService` Domain Service & Cost-Per-KM Analytics Engine

**Files:**
- Create: `lib/features/expenses/domain/services/expense_service.dart`
- Test: `test/features/expenses/expense_service_test.dart`

**Interfaces:**
- Consumes: `Expense`, `ExpenseCategory`, `ExpensePaymentMethod`, `Vehicle`, `Driver`, `Dispatch`.
- Produces: `ExpenseService`, `CreateExpenseInput`, `VehicleExpenseMetrics`, `FleetOperationalSummary`.

- [ ] **Step 1: Write failing tests for `ExpenseService`**
- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement `ExpenseService` in `lib/features/expenses/domain/services/expense_service.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 1**

---

### Task 2: Statutory Israeli A4 Expense Voucher PDF Generator (`ExpensePdfGenerator`)

**Files:**
- Create: `lib/core/pdf/expense_pdf_generator.dart`
- Test: `test/core/pdf/expense_pdf_test.dart`

**Interfaces:**
- Consumes: `Expense`, `CompanyInfo`, `Vehicle`, `Driver`.
- Produces: `ExpensePdfGenerator.generate(Expense expense, CompanyInfo company, ...) -> Future<Uint8List>`.

- [ ] **Step 1: Write failing test for `ExpensePdfGenerator`**
- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement `ExpensePdfGenerator` in `lib/core/pdf/expense_pdf_generator.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 2**

---

### Task 3: Presentation Controller & State Machine (`ExpensesController`)

**Files:**
- Create: `lib/features/expenses/presentation/controllers/expenses_controller.dart`
- Test: `test/features/expenses/expenses_controller_test.dart`

**Interfaces:**
- Consumes: `Expense`, `ExpenseService`, `Vehicle`, `Driver`, `Dispatch`.
- Produces: `ExpensesController`, `ExpensesState`.

- [ ] **Step 1: Write failing tests for `ExpensesController`**
- [ ] **Step 2: Run test to confirm it fails**
- [ ] **Step 3: Implement `ExpensesController` in `lib/features/expenses/presentation/controllers/expenses_controller.dart`**
- [ ] **Step 4: Run test to verify it passes**
- [ ] **Step 5: Commit Task 3**

---

### Task 4: Interactive Fleet Expenses UI in `lib/main.dart` & `mirn_system_preview.html`

**Files:**
- Modify: `lib/main.dart`
- Modify: `mirn_system_preview.html`

**Changes:**
- Update `_buildFleetScreen()` in `lib/main.dart`:
  - Segmented control / Tab toggle: `[أوامر النقل والإرساليات (משלוחים) | مصاريف الأسطول وتكلفة الكيلومتر (הוצאות צי)]`.
  - Fleet Expenses KPI Banner: Total Fleet Expenses (₪), Total Fuel (₪), Maintenance & Tires (₪), Fleet Cost / KM (₪/كم).
  - Vehicle Operational Efficiency Cards: per-truck cost/km breakdown, fuel vs. maintenance split.
  - Expense Category filter chips (All, Fuel, Maintenance, Tires, Driver Allowance, Licensing).
  - Primary button: `تسجيل سند صرف ومصروف جديد / שובר הוצאה חדש` opening `_showNewExpenseDialog()`:
    - Category picker, amount input, description, vehicle selector, driver selector, payment method, external reference, and notes.
    - Strict `.whenComplete(...)` text controller cleanup.
  - 1-click A4 PDF Expense Voucher preview via `ExpensePdfGenerator.generate`.
- Update `mirn_system_preview.html`:
  - Enhance `#view-fleet` with live expense logging, vehicle cost attribution, and simulated A4 Expense Voucher modal `#expenseVoucherPdfModal`.
- Run complete test suite and verify 100% green.
- Commit with message: `feat(ui): integrate fleet expenses and cost per km tracking into main navigation and preview`

- [ ] **Step 1: Implement UI in `lib/main.dart`**
- [ ] **Step 2: Update `mirn_system_preview.html`**
- [ ] **Step 3: Run full test suite**
- [ ] **Step 4: Commit Task 4**

---

### Task 5: Whole-Branch Verification & Senior Code Review

- [ ] **Step 1: Dispatch Senior Code Reviewer on Pro model to audit the complete branch changes**
- [ ] **Step 2: Address any findings**
- [ ] **Step 3: Merge `feat/fleet-expenses-cost-tracking` into `master` locally using `finishing-a-development-branch`**
- [ ] **Step 4: Confirm master working tree clean and all tests green**
