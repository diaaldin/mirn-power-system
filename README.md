# M.I.R.N POWER Management System
### מערכת ניהול מ.י.ר.ן פאוור | نظام م.ي.ر.ن باور لإدارة التجارة، الحسابات والأسطول

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Cloud_Firestore-FFCA28?logo=firebase&logoColor=black)
![Israel Statutory](https://img.shields.io/badge/Israel_Statutory-17%25_VAT-0038B8?logo=flag&logoColor=white)
![Tests](https://img.shields.io/badge/Tests-334%2F334_Passing_100%25-success)
![Architecture](https://img.shields.io/badge/Architecture-Clean_Domain_Driven-blueviolet)
![License](https://img.shields.io/badge/License-Proprietary-red)

---

## 🏢 Overview / نظرة عامة / סקירה כללית
The **M.I.R.N POWER Management System** is an enterprise cross-platform ERP and field logistics solution purpose-built for a Jerusalem-based market leader specializing in **Sanitary Ware, Marble & Granite, Building Stone, and Heavy Transportation Services**.

The system strictly adheres to **Israeli statutory accounting standards** (17% VAT, Tax ID `515892104`, Allocation Number support for invoices exceeding ₪25,000, dual Hebrew/Arabic branding, and tamper-evident sequential audit numbering).

---

## 🚀 Key Business Subsystems / الأنظمة الفرعية الثمانية

| # | Subsystem / النظام | Description / الوصف | Statutory & Domain Features |
|---|---|---|---|
| **1** | **Sales & POS Counter**<br>كاونتر المبيعات ونقاط البيع | Retail and wholesale counter sales with multi-currency & dual packaging. | • 17% VAT toggle (Before VAT vs. כולל מע"מ)<br>• Dual units: Square meters ($m^2$) $\leftrightarrow$ Boxes conversion<br>• Split payments: Cash, Checks, Debt Ledger<br>• Instant statutory A4 Tax Invoice (*חשבונית מס*) |
| **2** | **Returns & Credit Notes**<br>مردودات المبيعات وإشعارات الدائن | Seamless handling of returned stone, marble tiles, and damaged materials. | • Sequential `CRN-YYYY-xxxxx` numbering<br>• Refund methods: Cash refund vs. Accounts receivable credit<br>• Automatic stock reinstatement<br>• Statutory A4 Credit Note PDF (*חשבונית זיכוי*) |
| **3** | **Customer Ledger & Accounts**<br>حسابات وذمم العملاء والموردين | Full double-entry ledger with continuous debit/credit aging and balances. | • Multi-tier credit limit enforcement<br>• Automatic debt balance warnings during checkout<br>• Detailed transaction history and aging<br>• Statutory A4 Statement PDF (*כרטסת לקוח*) |
| **4** | **Receipts & Payment Intake**<br>سندات القبض والدفع | Official receipt voucher issuance with mixed payment ingestion. | • Sequential `REC-YYYY-xxxxx` vouchers<br>• Multi-instrument intake (Cash + Bank Checks)<br>• Automatic ledger balance reconciliation<br>• Statutory A4 Payment Receipt PDF (*קבלה*) |
| **5** | **Bank Checks Clearing Center**<br>مقاصة وحافظة الشيكات البنكية | 6-stage lifecycle tracking for all commercial checks (receivable & payable). | • Israeli bank directory (`הפועלים`, `לאומי`, `מזרחי`, `דיסקונט`, Palestinian banks)<br>• States: `Pending` $\rightarrow$ `Deposited` $\rightarrow$ `Cleared` / `Bounced` / `Transferred` / `Cancelled`<br>• **Automatic debt restoration** on bounced checks with audit log |
| **6** | **Supplier Purchases & Intake**<br>المشتريات وتوريد البضائع | Material intake from quarry and tile manufacturers with moving average costing. | • Moving Average Cost (MAC) auto-recalculation<br>• Supplier balance credit update<br>• Dual packaging intake with stock threshold alerts<br>• Statutory A4 Purchase Voucher PDF (*קליטת רכש*) |
| **7** | **Fleet Logistics & Dispatches**<br>أسطول الشاحنات وأوامر النقل | Heavy transportation scheduling, delivery tracking, and truck assignment. | • Odometer monotonic progression validation<br>• Truck weight capacity & status (`Active`, `Maintenance`, `Idle`)<br>• Linked sales invoice numbers<br>• Statutory Israeli Delivery Note PDF (*תעודת משלוח והובלה*) |
| **8** | **Fleet Operating Cost & Expenses**<br>مصاريف الشاحنات وتكلفة الكيلومتر | Per-vehicle expense logging (Fuel, Maintenance, Insurance, Licensing). | • Sequential `EXP-YYYY-xxxxx` numbering<br>• Real-time operating cost per kilometer (₪ / KM)<br>• Odometer tracking per expense<br>• Statutory A4 Expense Voucher PDF (*שובר תשלום והוצאה*) |

---

## 🏛️ Architecture & Technical Stack

```
lib/
├── core/
│   ├── di/
│   │   ├── service_locator.dart           # Decoupled abstract Service Locator
│   │   └── firestore_service_locator.dart # Cloud Firestore live bootstrap
│   ├── models/                            # Shared enums & localization helpers
│   ├── repositories/                      # 7 Abstract Repository Contracts
│   │   ├── in_memory/                     # Reactive in-memory implementations
│   │   └── firestore/                     # Production Cloud Firestore SDK Repositories
│   └── pdf/                               # 6 Statutory A4 PDF Document Generators
├── features/
│   ├── auth/                              # RBAC: Admin, Accountant, Cashier, Dispatcher
│   ├── sales/                             # POS Engine, VAT Calculator, Split Payments
│   ├── returns/                           # Credit Notes & Stock Reinstatement
│   ├── contacts/                          # Master Directory & Double-Entry Ledger
│   ├── receipts/                          # Payment Receipts & Mixed Ingestion
│   ├── checks/                            # 6-Stage Check State Machine & Bounce Engine
│   ├── purchases/                         # Supplier Intake & Moving Average Cost Engine
│   └── fleet/                             # Dispatch Logistics & Operating Cost/KM
├── firebase_options.dart                  # Multi-Platform (Web, Android, iOS, Desktop)
└── main.dart                              # Unified Application Shell & Navigation
```

---

## ⚖️ Israeli Statutory Compliance Standards

1. **VAT Engine (17%):**
   - Exact penny back-calculation from gross amounts:
     $$\text{VAT} = \text{Gross} - \left(\frac{\text{Gross}}{1.17}\right)$$
   - Tax-exclusive pricing forward calculation:
     $$\text{Total} = \text{Net} \times 1.17$$
2. **Allocation Number (*מספר הקצאה*):**
   - Built-in validation field for Israeli Tax Authority compliance on invoices $\ge$ ₪25,000.
3. **Immutable Audit Trails:**
   - Security rules strictly prevent updating or deleting financial transactions, invoices, credit notes, and clearing history.
4. **Non-Negative Stock Constraints:**
   - Inventory decrements are safeguarded against negative stock balances at both the domain model and database rule levels.
5. **Dual Hebrew & Arabic Document Branding:**
   - Tax Invoices, Receipts, Delivery Notes, and Expense Vouchers display bilingual metadata with Jerusalem company registration details (Tax ID: `515892104`).

---

## 📱 Multi-Platform Setup (Android, iOS, Web, Windows)

The application utilizes a single unified codebase connecting to the central `mirn-power-system` Firebase project:

- **Web:** Full high-density desktop dashboard for financial accountants and sales cashiers.
- **Android:** Optimized for field logistics, delivery drivers, and yard managers (`android/app/google-services.json`).
- **iOS:** Field and executive operations on iPhone and iPad (`ios/Runner/GoogleService-Info.plist`).
- **Windows / Desktop:** Fast local desktop execution for high-volume receipt and invoice printing.

---

## 🛠️ Getting Started & Installation

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.24.0 or higher)
- [Dart SDK](https://dart.dev) (v3.5.0 or higher)
- Firebase CLI & FlutterFire CLI (optional for advanced cloud configuration)

### Running Locally
```powershell
# 1. Clone repository
git clone https://github.com/diaaldin/mirn-power-system.git
cd mirn-power-system

# 2. Install dependencies
flutter pub get

# 3. Run application (Web / Chrome)
flutter run -d chrome

# 4. Run application (Windows Desktop)
flutter run -d windows
```

### Running Test Suite (100% Green Guarantee)
```powershell
# Run all core and feature tests (334 test cases)
dart test test/core/ test/features/ --reporter compact
```

---

## 🔒 Security & Cloud Rules

Production Firestore security rules are maintained in `firestore.rules`, featuring:
- Role-Based Access Control guards (Admin, Accountant, Cashier, Dispatcher).
- Atomic document transaction integrity checks.
- Zero-deletion policy on posted statutory ledgers.

---

## 👥 Roles & Permissions (RBAC)

| Role / الصلاحية | Permissions / الصلاحيات |
|---|---|
| **مدير النظام (Admin)** | Full administrative access across all 8 modules, configuration, and security rules. |
| **محاسب مالي (Accountant)** | Ledger management, Aging debt, Check clearing, Credit notes, Financial PDF exports. |
| **كاشير مبيعات (Cashier)** | Sales POS, Customer selection, Split payments, Receipt voucher issuance. |
| **سيدر نقليات (Dispatcher)** | Fleet dispatch orders, Truck odometer logging, Fuel & operating expense entry. |

---

## 📄 License & Rights
Proprietary Commercial Software. Developed specifically for **M.I.R.N POWER Management & Transportation**, Jerusalem. All rights reserved © 2026.
