# M.I.R.N POWER - Sales, Accounting, and Logistics Management System
## Design Specification

**System Name:** M.I.R.N POWER Management System  
**Company Subtitle:** כלים סניטריים, שיש, אבן והובלה | أدوات صحية، رخام، حجر، ونقل وشحن  
**Date:** 2026-11-13  
**Status:** Approved by Builder Review / Pending Final User Approval  
**Project Directory:** `C:\Users\dia81\.gemini\antigravity\scratch\sales_logistics_system`  
**Branding Asset:** `assets/images/logo.jpg` (M.I.R.N POWER Gold & Black Emblem)

---

## 1. Intent & Executive Summary
**M.I.R.N POWER** is a premier Israeli enterprise specializing in **Sanitary Ware, Marble, Stone, and Transportation/Hauling Services (כלים סניטריים, שיש, אבן והובלה)**. 

This project builds a unified, modern, cross-platform **Sales, Accounting, Inventory, and Logistics Management System** for M.I.R.N POWER. The system unifies counter sales, area ($m^2$) and unit/box inventory management, heavy-goods fleet dispatching, vehicle expense attribution, check tracking, and real-time customer and supplier statement ledgers (كشف حساب).

### Regional & Commercial Standards (Israel)
- **Currency:** Israeli New Shekel (**ILS / ₪**).
- **Taxation:** Configurable **VAT (مع"מ / ضريبة القيمة المضافة)** rate (default 17%).
- **Tax IDs:** Osek Murshe / Company ID (ח.פ. / עוסק מורשה / رقم المشتغل المرخص).
- **Israel Tax Authority Allocation Number (מספר הקצאה / رقم التخصيص):** Dedicated input field on B2B invoices compliant with Israeli Invoicing Law (Phase 1 manual entry, prepared for Sha'am API integration in future phases).
- **Trilingual Localization:** 
  1. **Arabic (Default, Native RTL)** - Primary daily operational language.
  2. **Hebrew (RTL)** - Official statutory documentation and invoice terminology.
  3. **English (LTR)** - Global/Administrative view.
- **Invoicing Documents:** A4 PDF Tax Invoices (חשבונית מס קבלה / חשבונית מס), Credit Invoices (חשבונית מס זיכוי), and Payment Receipts (קבלה / سند قبض).

---

## 2. Goals, Non-Goals & Anti-Goals

### 2.1 Goals
1. **Single Codebase Cross-Platform Execution:** Responsive Flutter application for Web (desktop browser administrative dashboard), Android, and iOS.
2. **Flexible Dual-Unit Inventory Management:** Support items measured by **Square Meter ($m^2$)** (essential for Marble and Stone), **Box (كرتونة)** (tiles and fixtures), or **Unit/Piece (حبة)** (toilets, sinks, faucets) with user-configurable unit settings and box conversion factors ($m^2$/box).
3. **Single Store/Warehouse Integrity:** Atomic Firestore inventory adjustments on completed sales (stock deduction), purchases (stock addition), and sales returns (stock restoration).
4. **Flexible Split Sales & Debt Warnings:** Support sales transactions split across Cash, Check, Bank Transfer, and On-Account (Customer Debt). Display real-time soft warnings when customer debt exceeds customer warning thresholds without blocking transactions.
5. **Pricing Input Flexibility:** One-click toggle on the sales invoice screen allowing cashiers to enter prices either **Tax-Inclusive (כולל מע"מ / شامل الضريبة)** or **Tax-Exclusive (قبل الضريبة)**, with automatic mathematical back-calculation of subtotals and VAT.
6. **Sales Returns & Credit Invoices:** Dedicated **Sales Return / Credit Invoice (חשבונית מס זיכוי)** module with sequential numbering (`CRN-2026-xxxxx`) to handle returned goods, restore inventory, and adjust customer balances.
7. **Standalone Payment Receipts (سند قبض / קבלה) & Supplier Payments (سند صرف):** Dedicated modules to collect debt payments and disburse supplier payments on an **Open-Balance Ledger** model.
8. **Back-Office Logistics & Dispatch:** Dispatch shipments linked to customers, delivery addresses, vehicles (name, license plate), and drivers, managed directly by office administrators.
9. **Fleet Cost Attribution:** Tag operational expenses (fuel, repairs, maintenance, driver allowance) to specific vehicles and drivers, tracking odometer readings to calculate net operational cost per vehicle and per kilometer.
10. **Complete Check Lifecycle:** Track post-dated checks through operational states: `Received/Issued` $\rightarrow$ `Deposited` $\rightarrow$ `Cleared` / `Bounced` / `Returned` / `Endorsed`. Bounced checks automatically re-apply debt to the debtor's balance.
11. **Detailed Statement of Account (كشف حساب):** Generate customer receivables and supplier payables ledgers with real-time running balances, date-range filtering, and 1-click A4 PDF export and WhatsApp sharing.
12. **Role-Based Access Control (RBAC):** Dedicated permission roles for `Owner / Admin` and `Accountant` (currently sharing full operational permissions, architected for future privilege separation).
13. **Executive Dashboard & Reports:** Filterable analytics across sales, shipments, expenses, and purchases by date, client, driver, and vehicle.

### 2.2 Non-Goals
1. **Full Double-Entry Corporate Accounting:** No manual Journal Entries (قيود يومية), Chart of Accounts (شجرة حسابات), or Balance Sheets. The system operates on an agile Operational Ledger.
2. **Driver Self-Service Mobile Portal:** Drivers do not require a separate app login for GPS routing or signature capture in this phase; dispatch status is updated by office staff.
3. **POS Thermal Slip Printing:** Standard A4 PDF documents are used for all invoices, payment receipts, and delivery notes.
4. **Automated External Push Alerts:** No SMS or automated push notifications for check due dates; dashboard filters and visual badges suffice.
5. **Multi-Branch / Multi-Warehouse Transfers:** All stock is managed in a single central store/warehouse.
6. **Offline Data Synchronization:** The app operates online-first with active internet connectivity.

### 2.3 Anti-Goals
1. **Hard Credit Blocking:** The system must NEVER hard-block a sale when a customer exceeds their debt limit; it must alert the user clearly with a warning prompt and allow them to proceed.
2. **Non-Atomic Inventory & Balance Mutations:** Financial balances and stock counts must never be updated with loose, uncoordinated client writes; all balance updates must occur within atomic Firestore transactions.

---

## 3. System Architecture & Tech Stack

### 3.1 Technology Foundation
- **Frontend Framework:** Flutter 3.x (Dart 3.x) targeting Web, Android, and iOS.
- **State Management & DI:** `flutter_riverpod` + `riverpod_annotation` (Feature-First Clean Architecture).
- **Backend & Cloud:** Firebase
  - **Firebase Authentication:** Email/Password authentication with custom claims/role storage.
  - **Cloud Firestore:** NoSQL database with transactional consistency.
  - **Firebase Storage:** Storage for company logos, product images, and delivery attachments.
  - **Firebase Hosting:** Web deployment.
  - **Cloud Functions:** For backend aggregations, sequential numbering guarantees, and scheduled report rollups.
- **Localization:** `intl` with custom RTL delegate; dynamic locale switching (`ar`, `he`, `en`).
- **PDF & Printing:** `pdf` and `printing` with embedded Google Fonts (Cairo for Arabic, Noto Sans Hebrew for Hebrew, Roboto for English).

### 3.2 Feature-First Structure
```text
lib/
├── core/
│   ├── constants/             # App colors (M.I.R.N Gold & Charcoal Black), VAT rates
│   ├── localization/          # AR, HE, EN arb files & delegates
│   ├── theme/                 # Luxury Gold/Dark and Clean Light themes
│   ├── utils/                 # Currency formatters (ILS ₪), date formatters, PDF helpers
│   └── widgets/               # Responsive layouts, Arabic/Hebrew data tables, custom dialogs
└── features/
    ├── auth/                  # Login, user session, role verification
    ├── inventory/             # Products catalog, unit/meter config, stock adjustments
    ├── sales/                 # Invoicing, POS checkout, split payment, debt warning, pricing toggle
    ├── returns/               # Sales returns, credit notes (חשבונית זיכوي), stock restoration
    ├── receipts/              # Standalone payment receipts (سند قبض / קבלה)
    ├── purchases/             # Supplier bills, stock intake, supplier payment vouchers (سند صرف)
    ├── expenses/              # Fleet expenses, driver tagging, general overhead, fuel/mileage
    ├── logistics/             # Dispatches, delivery routes, status updates
    ├── fleet/                 # Vehicles & drivers directory, odometer logs
    ├── checks/                # Check registry, lifecycle state machine, due check views
    ├── accounts/              # Customer/supplier balances, Statement of Account (كشف حساب)
    └── reports/               # Executive dashboard, filterable aggregations, CSV/PDF export
```

---

## 4. Data Models & Firestore Schema

### 4.1 Products (`products`)
```typescript
interface Product {
  id: string;
  name: string;              // e.g., "שיש קררה איטלקי 60x120" / "رخام كرارا إيطالي"
  sku: string;
  category: 'sanitary' | 'marble' | 'stone' | 'transport' | 'other';
  unitType: 'meter' | 'box' | 'piece';
  meterPerBox?: number;      // e.g., 1.44 m² per box (for tiles/marble)
  piecesPerBox?: number;     // e.g., 8 pieces per box
  purchaseCost: number;      // Cost price before VAT
  sellingPrice: number;      // Selling price (base)
  currentStock: number;      // Current stock in primary unit
  minStockAlert: number;     // Low-stock warning threshold
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### 4.2 Contacts (`contacts` - Customers & Suppliers)
```typescript
interface Contact {
  id: string;
  type: 'customer' | 'supplier' | 'both';
  name: string;
  phone: string;
  address: string;
  taxId: string;             // Osek Murshe / ח.פ. / ת.ז.
  debtWarningLimit: number;  // Threshold for warning banner
  currentBalance: number;    // Positive = owes money (debtor), Negative = credit
  notes?: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

### 4.3 Sales Invoices (`sales`)
```typescript
interface SaleInvoice {
  id: string;
  invoiceNumber: string;     // Sequential: INV-2026-00001
  date: Timestamp;
  customerId: string;
  customerName: string;
  customerTaxId: string;
  isTaxInclusiveInput: boolean; // Flag indicating if line prices were entered including VAT
  items: Array<{
    productId: string;
    productName: string;
    unitType: 'meter' | 'box' | 'piece';
    quantity: number;
    unitPrice: number;       // Unit price before VAT
    discountPercent: number;
    subtotal: number;
  }>;
  subtotal: number;          // Subtotal before VAT
  vatRate: number;           // 0.17 (17%)
  vatAmount: number;
  totalAmount: number;       // Final amount in ILS
  payments: Array<{
    method: 'cash' | 'check' | 'bank_transfer' | 'debt';
    amount: number;
    reference?: string;      // Check number or bank confirmation
  }>;
  allocationNumber?: string; // Israel Tax Authority Allocation Number (מספר הקצאה)
  dispatchId?: string;       // Linked delivery dispatch if hauling is needed
  notes?: string;
  createdBy: string;
  createdAt: Timestamp;
}
```

### 4.4 Sales Returns / Credit Notes (`credit_notes`)
```typescript
interface CreditNote {
  id: string;
  creditNoteNumber: string;  // Sequential: CRN-2026-00001
  date: Timestamp;
  originalInvoiceId?: string;
  originalInvoiceNumber?: string;
  customerId: string;
  customerName: string;
  customerTaxId: string;
  items: Array<{
    productId: string;
    productName: string;
    unitType: 'meter' | 'box' | 'piece';
    quantity: number;
    unitPrice: number;
    subtotal: number;
  }>;
  subtotal: number;
  vatRate: number;
  vatAmount: number;
  totalAmount: number;
  refundMethod: 'debt_credit' | 'cash_refund' | 'bank_transfer';
  reason?: string;
  createdBy: string;
  createdAt: Timestamp;
}
```

### 4.5 Standalone Payment Receipts (`receipts`)
```typescript
interface PaymentReceipt {
  id: string;
  receiptNumber: string;     // Sequential: REC-2026-00001
  date: Timestamp;
  partyType: 'customer' | 'supplier'; // Receipt from customer (سند قبض) or Payment to supplier (سند صرف)
  contactId: string;
  contactName: string;
  amount: number;
  payments: Array<{
    method: 'cash' | 'check' | 'bank_transfer';
    amount: number;
    reference?: string;
    checkId?: string;
  }>;
  notes?: string;
  createdBy: string;
  createdAt: Timestamp;
}
```

### 4.6 Fleet & Drivers (`vehicles`, `drivers`)
```typescript
interface Vehicle {
  id: string;
  name: string;              // e.g., "Volvo FH 500 Heavy Truck"
  plateNumber: string;       // e.g., "12-345-67"
  modelYear?: number;
  currentOdometer: number;   // Kilometers
  status: 'active' | 'maintenance' | 'inactive';
  notes?: string;
}

interface Driver {
  id: string;
  fullName: string;
  phone: string;
  licenseNumber: string;
  status: 'active' | 'inactive';
  notes?: string;
}
```

### 4.7 Dispatches & Transportation (`dispatches`)
```typescript
interface Dispatch {
  id: string;
  dispatchNumber: string;    // Sequential: DSP-2026-00001
  date: Timestamp;
  saleId?: string;
  invoiceNumber?: string;
  customerId: string;
  customerName: string;
  customerPhone: string;
  deliveryAddress: string;
  cargoDescription: string;  // e.g., "150 m² Marble + 4 Toilets"
  vehicleId: string;
  vehicleName: string;
  plateNumber: string;
  driverId: string;
  driverName: string;
  status: 'pending' | 'dispatched' | 'delivered' | 'returned' | 'cancelled';
  notes?: string;
  updatedAt: Timestamp;
}
```

### 4.8 Expenses (`expenses`)
```typescript
interface Expense {
  id: string;
  expenseNumber: string;     // Sequential: EXP-2026-00001
  date: Timestamp;
  category: 'fuel' | 'maintenance' | 'tires' | 'driver_allowance' | 'licensing_insurance' | 'rent' | 'utilities' | 'other';
  amount: number;
  description: string;
  vehicleId?: string;        // Tagged vehicle for fleet costing
  driverId?: string;         // Tagged driver
  odometerReading?: number;  // Current odometer at expense time
  paymentMethod: 'cash' | 'bank_transfer' | 'check';
  reference?: string;
  createdBy: string;
  createdAt: Timestamp;
}
```

### 4.9 Checks Registry (`checks`)
```typescript
interface CheckRecord {
  id: string;
  checkNumber: string;
  bankName: string;
  branchNumber: string;
  accountNumber: string;
  amount: number;
  dueDate: Timestamp;
  type: 'received' | 'issued';  // received from customer vs. issued to supplier
  partyId: string;
  partyName: string;
  relatedTransactionId: string; // saleId, purchaseId, or receiptId
  status: 'pending' | 'deposited' | 'cleared' | 'bounced' | 'returned' | 'endorsed';
  endorsedToPartyId?: string;   // If endorsed to a supplier
  history: Array<{
    status: string;
    changedAt: Timestamp;
    notes?: string;
    changedBy: string;
  }>;
  createdAt: Timestamp;
}
```

### 4.10 Statement of Account Ledger (`statement_entries`)
Every balance-affecting event writes a record to `statement_entries`:
```typescript
interface StatementEntry {
  id: string;
  contactId: string;
  contactType: 'customer' | 'supplier';
  date: Timestamp;
  type: 'sale_invoice' | 'credit_note' | 'payment_receipt' | 'check_bounced' | 'purchase_invoice' | 'supplier_payment' | 'adjustment';
  referenceNumber: string;      // INV-001, CRN-001, REC-001, CHK-1234
  debit: number;                // Increases debtor balance
  credit: number;               // Decreases debtor balance
  runningBalance: number;       // Balance after transaction
  description: string;
}
```

---

## 5. Key Workflows & Business Logic

### 5.1 Sales Checkout with Pricing Toggle & Split Payment
1. Cashier chooses customer or "General Customer" (عميل عام / לקוח כללי).
2. The cashier selects pricing input mode via a prominent toggle:
   - **Mode A: Including VAT (כולל מע"מ / شامل الضريبة):** Cashier enters ₪117 per item. System stores unit price before VAT as $117 / 1.17 = ₪100.00$, VAT as $₪17.00$.
   - **Mode B: Before VAT (قبل الضريبة / לפני מע"מ):** Cashier enters ₪100 per item. System computes 17% VAT as $₪17.00$, total as $₪117.00$.
3. Real-time **Debt Warning**: If customer's debt + remaining unpaid amount > `debtWarningLimit`, a warning banner alerts the user:
   > *"تنبيه: رصيد العميل الحالي (₪X) يتجاوز سقف المديونية المحدد (₪Y)."*
   The cashier can continue with the sale.
4. Split payments: User enters breakdown (Cash + Check + Bank Transfer + On Account).
5. On submit, an atomic Firestore transaction:
   - Creates the `SaleInvoice`.
   - Decrements stock from `products` (calculating boxes or $m^2$ accurately).
   - If checks were entered, creates `CheckRecord` items with status `pending`.
   - If an On-Account amount exists, increments `Contact.currentBalance` and writes a debit to `statement_entries`.

### 5.2 Israel-Compliant A4 Invoicing
The system produces an A4 PDF adhering to Israeli commercial standards:
- **Header:** Features **M.I.R.N POWER** gold-and-black logo, company name, address, phone, and Osek Murshe / ח.פ. ID.
- **Title:** "חשבונית מס קבלה / فاتورة ضريبية وسند قبض" (or "חשבונית מס / فاتورة ضريبية" if unpaid/on-account).
- **Sequential Number & Date:** Clean timestamp and non-repeating sequence number.
- **Israel Tax Authority Allocation Number (מספר הקצאה):** Displayed prominently when provided.
- **Customer Section:** Name, Address, and Tax ID (ת.ז. / ח.פ.).
- **Itemized Table:** Product Name, Unit Type ($m^2$, Box, Piece), Quantity, Unit Price, Line Total.
- **Summary:** Subtotal before VAT, VAT Rate (17%), Total VAT amount, Grand Total in ILS (₪).
- **Payment Breakdown:** Detail table showing amounts paid via Cash, Check numbers/banks/due dates, Bank Transfer, and On-Account balance.

### 5.3 Sales Return & Credit Invoices (חשבונית מס זיכוי)
1. Staff selects original sale (optional) or selects customer and returned products.
2. In an atomic transaction:
   - Creates `CreditNote` record.
   - Restocks returned units into `products.currentStock`.
   - Decrements customer debt in `Contact.currentBalance` and logs a credit entry in `statement_entries`.
   - Generates A4 Credit Note PDF with company branding.

### 5.4 Check State Machine & Bounce Protection
- When a check bounces (`status = 'bounced'`), an atomic transaction:
  - Updates check status to `bounced`.
  - Re-applies the check amount as a debit to the customer's balance.
  - Adds a `check_bounced` record in `statement_entries` so the customer's account statement accurately shows the bounce and restores the debt.

### 5.5 Fleet & Dispatch Management
- Dispatches are assigned to an active vehicle and driver, with customer delivery address and cargo notes.
- When vehicle expenses (fuel, maintenance, licensing) are recorded with odometer readings, the system calculates:
  - **Operating Cost per Kilometer (₪/KM)**.
  - **Total Expenses per Truck / Driver**.
  - Dispatch completion rate and delivery logs.

---

## 6. What's Left to the Builder
1. Implementation of Material 3 color theme using M.I.R.N POWER luxury gold (`#D4AF37` / `#C5A059`) and deep charcoal/slate (`#1E1E24`).
2. Exact responsive table layouts with sticky headers for desktop screens and adaptive card views for mobile screens.
3. Firestore Compound Security Rules ensuring authenticated users only access authorized tenant data.
