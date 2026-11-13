# M.I.R.N POWER Management System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a robust, cross-platform Flutter sales, accounting, inventory, and logistics management system for M.I.R.N POWER featuring dual-unit inventory, split payments, check lifecycle, fleet costing, and Israeli-standard trilingual A4 PDF generation.

**Architecture:** Feature-first Flutter application with Riverpod state management. Pure business logic domain entities and calculation engines isolated for deterministic TDD unit testing, integrated with Firestore repositories and responsive Material 3 UI.

**Tech Stack:** Flutter 3.x / Dart 3.x, `flutter_riverpod`, `intl`, `pdf`, `printing`, `google_fonts`.

**Spec:** `docs/superpowers/specs/2026-11-13-sales-accounting-logistics-design.md`

## Global Constraints
- Currency: Israeli New Shekel (ILS / ₪).
- Statutory VAT Rate: 17% (configurable default 0.17).
- Language support: Arabic (Default, Native RTL), Hebrew (RTL statutory invoices), English (LTR).
- Branding: Luxury Gold (`#C5A059`, `#D4AF37`) & Charcoal/Black (`#1E1E24`, `#121214`), using `assets/images/logo.jpg`.
- Anti-Goal: Never hard-block sales on customer debt limit; display soft warning prompt only.
- Sequential document IDs: `INV-2026-xxxxx`, `CRN-2026-xxxxx`, `REC-2026-xxxxx`, `DSP-2026-xxxxx`, `EXP-2026-xxxxx`.

## Review Focus
1. Precision of VAT inclusive back-calculation ($117 \rightarrow ₪100.00$ base + $₪17.00$ VAT) avoiding floating-point rounding drifts.
2. Fractional area-to-box conversions (e.g., $15.5 m^2$ with $1.44 m^2/\text{box}$) preventing stock rounding losses.
3. Check bounce re-applying exact debt amount to customer's running balance in statement ledger.
4. Split payments validation rejecting transactions where Cash + Check + Transfer + Debt does not equal the invoice total.
5. Soft debt warning correctly triggering when current debt + new debt exceeds warning limit, but allowing confirmation.

---

### Task 1: Project Scaffolding & Dependencies Setup

**Files:**
- Create: `pubspec.yaml`
- Create: `lib/main.dart`
- Create: `test/widget_test.dart`

**Interfaces:**
- Produces: Base Flutter environment, assets registration, theme foundations.

- [ ] **Step 1: Write pubspec.yaml with required dependencies**
Define `flutter_riverpod`, `intl`, `pdf`, `printing`, `google_fonts`, `flutter_test`, and register `assets/images/logo.jpg`.

- [ ] **Step 2: Verify Flutter package get**
Run: `flutter pub get`
Expected: Resolves dependencies successfully.

- [ ] **Step 3: Implement minimal main.dart entrypoint**
Setup `ProviderScope` and base `MaterialApp`.

- [ ] **Step 4: Run initial test**
Run: `flutter test test/widget_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add pubspec.yaml pubspec.lock lib/main.dart test/widget_test.dart
git commit -m "chore: scaffold flutter project and register dependencies and assets"
```

---

### Task 2: Localization, Currency & Theme Foundations

**Files:**
- Create: `lib/core/constants/app_colors.dart`
- Create: `lib/core/localization/app_locale.dart`
- Create: `lib/core/utils/currency_formatter.dart`
- Test: `test/core/currency_formatter_test.dart`

**Interfaces:**
- Produces: `AppColors.gold`, `AppColors.charcoal`, `formatCurrency(double amount) -> String`, `AppLocale` switching (`ar`, `he`, `en`).

- [ ] **Step 1: Write failing currency formatter test**
Test that `formatCurrency(1250.5)` returns `"₪1,250.50"` and handles zero and negative numbers formatted with Shekel symbol.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/currency_formatter_test.dart`
Expected: FAIL (file or function not found)

- [ ] **Step 3: Implement AppColors, AppLocale, and CurrencyFormatter**
Implement `lib/core/constants/app_colors.dart` and `lib/core/utils/currency_formatter.dart`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/core/currency_formatter_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/core/ test/core/
git commit -m "feat(core): add luxury theme colors, localization constants and ILS currency formatter"
```

---

### Task 3: Dual-Unit Inventory Model & Conversion Engine

**Files:**
- Create: `lib/features/inventory/domain/models/product.dart`
- Create: `lib/features/inventory/domain/services/unit_converter.dart`
- Test: `test/features/inventory/unit_converter_test.dart`

**Interfaces:**
- Consumes: `AppColors`
- Produces: `Product` model, `UnitConverter.boxesToMeters(boxes, meterPerBox)`, `UnitConverter.metersToBoxes(meters, meterPerBox)`, `UnitConverter.calculateStockReduction(product, quantity, unitType)`.

- [ ] **Step 1: Write failing test for UnitConverter**
Verify:
1. Converting 10 boxes with $1.44 m^2/\text{box}$ yields $14.4 m^2$.
2. Converting $14.4 m^2$ with $1.44 m^2/\text{box}$ yields 10.0 boxes.
3. Selling 5 boxes of a meter-based product deducts $5 \times \text{meterPerBox}$ from primary stock.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/inventory/unit_converter_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement Product model and UnitConverter service**
Add `Product` dataclass with `unitType` (`meter`, `box`, `piece`) and `meterPerBox` properties, plus conversion math.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/inventory/unit_converter_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/inventory/ test/features/inventory/
git commit -m "feat(inventory): add Product model and dual-unit m2/box conversion engine"
```

---

### Task 4: VAT Calculation Engine & Israel Allocation Number

**Files:**
- Create: `lib/features/sales/domain/services/vat_calculator.dart`
- Test: `test/features/sales/vat_calculator_test.dart`

**Interfaces:**
- Produces: `VatCalculator.calculateFromInclusive(totalInclusive, vatRate)` and `VatCalculator.calculateFromExclusive(subtotalExclusive, vatRate)`, returning subtotal, VAT amount, and grand total.

- [ ] **Step 1: Write failing test for VatCalculator**
Test:
1. Tax-Inclusive entry: ₪117.00 at 17% VAT $\rightarrow$ Subtotal: ₪100.00, VAT: ₪17.00, Total: ₪117.00.
2. Tax-Exclusive entry: ₪100.00 at 17% VAT $\rightarrow$ Subtotal: ₪100.00, VAT: ₪17.00, Total: ₪117.00.
3. Precision check: ₪100.00 inclusive at 17% $\rightarrow$ Subtotal: ₪85.47, VAT: ₪14.53, Total: ₪100.00 (sum matches exactly without penny drift).

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/sales/vat_calculator_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement VatCalculator**
Implement math using 2-decimal rounded calculation with exact penny balance matching.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/sales/vat_calculator_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/sales/domain/services/vat_calculator.dart test/features/sales/vat_calculator_test.dart
git commit -m "feat(sales): implement VAT calculation engine with tax-inclusive back-calculation"
```

---

### Task 5: Contacts, Customer Debt Warning & Ledger Entries

**Files:**
- Create: `lib/features/accounts/domain/models/contact.dart`
- Create: `lib/features/accounts/domain/models/statement_entry.dart`
- Create: `lib/features/accounts/domain/services/debt_warning_evaluator.dart`
- Test: `test/features/accounts/debt_warning_test.dart`

**Interfaces:**
- Produces: `Contact` entity, `StatementEntry` entity, `DebtWarningEvaluator.evaluate(contact, additionalDebt) -> DebtWarningResult`.

- [ ] **Step 1: Write failing test for DebtWarningEvaluator**
Test:
1. When `currentBalance` (₪4,000) + `additionalDebt` (₪2,000) > `debtWarningLimit` (₪5,000), return `isExceeded: true`, with exceeded amount ₪1,000.
2. When within limit, return `isExceeded: false`.
3. General customer with 0 limit does not trigger false alerts.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/accounts/debt_warning_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement Contact, StatementEntry, and DebtWarningEvaluator**
Implement models and evaluation logic.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/accounts/debt_warning_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/accounts/ test/features/accounts/
git commit -m "feat(accounts): implement Contact, StatementEntry and soft debt warning evaluator"
```

---

### Task 6: Sales Invoicing & Split Payment Validation Engine

**Files:**
- Create: `lib/features/sales/domain/models/sale_invoice.dart`
- Create: `lib/features/sales/domain/models/payment_split.dart`
- Create: `lib/features/sales/domain/services/sales_service.dart`
- Test: `test/features/sales/sales_service_test.dart`

**Interfaces:**
- Consumes: `Product`, `Contact`, `VatCalculator`, `StatementEntry`
- Produces: `SaleInvoice` model, `SalesService.validateSplitPayment(totalAmount, payments)`, `SalesService.processSale(...)`.

- [ ] **Step 1: Write failing test for SalesService**
Test:
1. Split payments summing to less than invoice total fails with `InvalidPaymentTotalException`.
2. Split payment (Cash ₪500, Check ₪1,000, Debt ₪500 on total ₪2,000) passes validation.
3. On-account payment amount updates customer `currentBalance` and produces a `statement_entries` debit record.
4. Stock quantities are decremented correctly for line items.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/sales/sales_service_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement SaleInvoice, PaymentSplit, and SalesService**
Implement data models and validation/processing logic.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/sales/sales_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/sales/ test/features/sales/sales_service_test.dart
git commit -m "feat(sales): add SaleInvoice, PaymentSplit and split payment validation engine"
```

---

### Task 7: Sales Returns & Credit Invoices (חשבונית מס זיכוי)

**Files:**
- Create: `lib/features/returns/domain/models/credit_note.dart`
- Create: `lib/features/returns/domain/services/credit_note_service.dart`
- Test: `test/features/returns/credit_note_service_test.dart`

**Interfaces:**
- Consumes: `Product`, `Contact`, `SaleInvoice`, `StatementEntry`
- Produces: `CreditNote` model, `CreditNoteService.processReturn(...)`.

- [ ] **Step 1: Write failing test for CreditNoteService**
Test:
1. Returning 2 boxes of marble restocks the inventory.
2. Debt refund method decrements customer's debt balance and creates a `statement_entries` credit record.
3. Numbering format matches `CRN-2026-xxxxx`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/returns/credit_note_service_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement CreditNote and CreditNoteService**
Implement model and return handling logic.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/returns/credit_note_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/returns/ test/features/returns/
git commit -m "feat(returns): implement CreditNote model and stock-restoring return service"
```

---

### Task 8: Check Registry & Lifecycle State Machine

**Files:**
- Create: `lib/features/checks/domain/models/check_record.dart`
- Create: `lib/features/checks/domain/services/check_state_machine.dart`
- Test: `test/features/checks/check_state_machine_test.dart`

**Interfaces:**
- Consumes: `Contact`, `StatementEntry`
- Produces: `CheckRecord`, `CheckStateMachine.transition(check, newStatus, {notes, endorsedToPartyId})`.

- [ ] **Step 1: Write failing test for CheckStateMachine**
Test:
1. Check can transition `pending` $\rightarrow$ `deposited` $\rightarrow$ `cleared`.
2. Bouncing a check (`status = 'bounced'`) returns debtor balance mutation (+check amount) and generates a `check_bounced` statement entry.
3. Invalid transitions (e.g. from `cleared` to `pending`) throw `InvalidStateTransitionException`.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/checks/check_state_machine_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement CheckRecord and CheckStateMachine**
Implement state machine and balance restoration rules.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/checks/check_state_machine_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/checks/ test/features/checks/
git commit -m "feat(checks): implement CheckRecord and lifecycle state machine with bounce protection"
```

---

### Task 9: Fleet, Dispatches & Vehicle Expense Costing

**Files:**
- Create: `lib/features/fleet/domain/models/vehicle.dart`
- Create: `lib/features/fleet/domain/models/driver.dart`
- Create: `lib/features/logistics/domain/models/dispatch.dart`
- Create: `lib/features/expenses/domain/models/expense.dart`
- Create: `lib/features/fleet/domain/services/fleet_cost_calculator.dart`
- Test: `test/features/fleet/fleet_cost_calculator_test.dart`

**Interfaces:**
- Produces: `Vehicle`, `Driver`, `Dispatch`, `Expense`, `FleetCostCalculator.calculateCostPerKm(expenses, startOdometer, endOdometer)`.

- [ ] **Step 1: Write failing test for FleetCostCalculator**
Test:
1. Summing expenses tagged to vehicle (fuel ₪500, maintenance ₪300) over 400 km traveled calculates ₪2.00 / km.
2. Handling zero km delta without division by zero errors.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/fleet/fleet_cost_calculator_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement Fleet models and FleetCostCalculator**
Implement entities and cost aggregation methods.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/fleet/fleet_cost_calculator_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/fleet/ lib/features/logistics/ lib/features/expenses/ test/features/fleet/
git commit -m "feat(fleet): implement Fleet, Dispatch, Expense models and cost-per-km calculator"
```

---

### Task 10: Israeli Standard A4 PDF Invoicing & Statement Generator

**Files:**
- Create: `lib/core/pdf/invoice_pdf_generator.dart`
- Create: `lib/core/pdf/statement_pdf_generator.dart`
- Test: `test/core/pdf/invoice_pdf_test.dart`

**Interfaces:**
- Consumes: `SaleInvoice`, `Contact`, `StatementEntry`, `AppColors`
- Produces: `InvoicePdfGenerator.generate(saleInvoice, companyInfo) -> Future<Uint8List>`, `StatementPdfGenerator.generate(contact, entries, dateRange) -> Future<Uint8List>`.

- [ ] **Step 1: Write failing test for InvoicePdfGenerator**
Test that `InvoicePdfGenerator.generate(...)` generates valid non-empty PDF bytes, includes company Tax ID and Israel Tax Authority Allocation Number when present.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/core/pdf/invoice_pdf_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement A4 Tax Invoice & Statement PDF Generators**
Implement layout using `pdf` package widgets with trilingual headers, logo embedding, itemized tables, VAT summary, and payment breakdown.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/core/pdf/invoice_pdf_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/core/pdf/ test/core/pdf/
git commit -m "feat(pdf): implement Israeli standard A4 Tax Invoice and Statement of Account PDF generator"
```

---

### Task 11: Luxury UI Shell, Navigation & Theme System

**Files:**
- Create: `lib/core/theme/mirn_theme.dart`
- Create: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Create: `lib/features/dashboard/presentation/widgets/navigation_shell.dart`
- Test: `test/features/dashboard/navigation_shell_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppLocale`
- Produces: `MirnTheme.darkTheme`, `MirnTheme.lightTheme`, `NavigationShell` with sidebar/rail for desktop and drawer/navigation bar for mobile.

- [ ] **Step 1: Write failing test for NavigationShell**
Verify that `NavigationShell` renders navigation items for Sales, Inventory, Customers/Suppliers, Checks, Fleet & Logistics, and Reports with Arabic RTL support.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/dashboard/navigation_shell_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement MirnTheme and NavigationShell**
Style with gold accents, charcoal cards, and responsive adaptive layout.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/dashboard/navigation_shell_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/core/theme/ lib/features/dashboard/ test/features/dashboard/
git commit -m "feat(ui): implement M.I.R.N luxury theme and responsive navigation shell"
```

---

### Task 12: Sales POS UI with Split Payments & Pricing Toggle

**Files:**
- Create: `lib/features/sales/presentation/screens/sales_screen.dart`
- Create: `lib/features/sales/presentation/widgets/pricing_mode_toggle.dart`
- Create: `lib/features/sales/presentation/widgets/split_payment_dialog.dart`
- Create: `lib/features/sales/presentation/widgets/debt_warning_dialog.dart`
- Test: `test/features/sales/sales_screen_test.dart`

**Interfaces:**
- Consumes: `VatCalculator`, `DebtWarningEvaluator`, `SalesService`
- Produces: POS screen enabling quick item additions, $m^2$/box selection, tax-inclusive toggle, soft debt warning alert, and split payment settlement.

- [ ] **Step 1: Write failing widget test for PricingModeToggle**
Verify that switching toggle changes price display and recalculates subtotal and VAT dynamically.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/sales/sales_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement SalesScreen and supporting widgets**
Implement POS view, tax toggle, debt warning dialog, and split payment sheet.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/sales/sales_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/sales/presentation/ test/features/sales/sales_screen_test.dart
git commit -m "feat(sales-ui): implement POS screen with pricing mode toggle, debt warning and split payments"
```

---

### Task 13: Statement of Account (كشف حساب) & Check Registry UI

**Files:**
- Create: `lib/features/accounts/presentation/screens/statement_screen.dart`
- Create: `lib/features/checks/presentation/screens/checks_screen.dart`
- Test: `test/features/accounts/statement_screen_test.dart`

**Interfaces:**
- Consumes: `StatementEntry`, `CheckRecord`, `InvoicePdfGenerator`, `StatementPdfGenerator`
- Produces: Interactive Statement of Account screen with running balance, date filter, 1-click A4 PDF generation, and Checks Management screen.

- [ ] **Step 1: Write failing test for StatementScreen**
Verify statement table displays date, reference number, debit, credit, running balance, and has a PDF export action.

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/features/accounts/statement_screen_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement StatementScreen and ChecksScreen**
Build screens with luxury card styling, badges for check statuses, and PDF export hooks.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/features/accounts/statement_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/features/accounts/presentation/ lib/features/checks/presentation/ test/features/accounts/statement_screen_test.dart
git commit -m "feat(accounts-ui): implement Statement of Account ledger screen and Check registry UI"
```
