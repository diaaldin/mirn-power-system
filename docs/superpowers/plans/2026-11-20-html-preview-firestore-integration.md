# HTML Preview Full Firestore Integration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every form, button, and action in `mirn_system_preview.html` write to and read from Cloud Firestore, update the DOM lists in real-time, and produce printable PDF documents — turning the static HTML mockup into a fully functional Firebase-connected web application.

**Architecture:** A single-page HTML application using Firebase Web SDK (compat mode, already loaded). On page load, Firebase Anonymous Auth signs the user in, then all form submissions write to Firestore collections and simultaneously update the DOM. PDF generation uses `window.print()` with scoped print stylesheets targeting `.pdf-preview-modal .pdf-paper` containers. A central `FirebaseService` module initializes Firebase once, provides `db` and `auth` references, and exposes a `withAuth(fn)` wrapper that ensures auth before any Firestore operation.

**Tech Stack:** HTML/JS (vanilla), Firebase Web SDK 10.8.0 (compat), Tailwind CSS (CDN), `window.print()` for PDF.

**Spec:** User-reported bugs (conversation context) + `mirn_system_preview.html` (3,456 lines)

## Global Constraints

- **Target file:** `C:\Users\dia81\.gemini\antigravity\brain\1aceba9d-9aaa-4661-a8e6-620f37409059\mirn_system_preview.html` — all changes go in this single file.
- **Firebase project:** `mirn-power-system` — config already in `triggerCloudSeed()` lines 164-171.
- **Firestore collections:** `products`, `contacts`, `sales`, `purchases`, `checks`, `dispatches`, `expenses`, `receipts`, `credit_notes`.
- **Auth requirement:** Firestore rules require `request.auth != null` — Anonymous Auth must be used (or rules temporarily relaxed to `allow read, write: if true` for development).
- **VAT rate:** 17% (Israeli law). All financial calculations must use this.
- **Language:** UI text is bilingual Arabic/Hebrew. Keep existing copy unchanged.
- **No external dependencies** beyond what's already loaded (Firebase compat scripts, Tailwind CDN).
- **Print/PDF approach:** Use `window.print()` targeting the visible A4 preview modal container. Add a `@media print` stylesheet that hides everything except the `.pdf-paper` div.

## Review Focus

1. **Firebase Auth race condition:** If a user clicks a button before Anonymous Auth completes, the Firestore write will fail with PERMISSION_DENIED — `withAuth()` must `await` auth readiness, and the seeder must call `withAuth()` too.
2. **Duplicate document IDs:** Functions that use `Date.now()` for IDs could collide if two rapid clicks happen — use `db.collection().doc()` auto-ID instead, or combine timestamp + random suffix.
3. **DOM ↔ Firestore consistency on page reload:** The HTML has hardcoded initial data (inventory rows, customer `<option>` elements, check cards). After seeding, a page reload still shows the old hardcoded data, not what's in Firestore — Task 1 should load data from Firestore on page init.
4. **Print stylesheet specificity:** `@media print` must hide the dark overlay and modal chrome while showing only the white A4 paper div; without enough specificity, Tailwind's utility classes could override.
5. **Number formatting round-trip:** Values displayed as `₪ 38,200.00` are parsed back with `replace(',', '')` — a locale that uses `.` as thousands separator would break parsing; ensure consistent `en-US` locale for `toLocaleString` and strip all non-numeric chars when parsing.

---

### Task 0: Firebase Foundation — Auth Init + withAuth Wrapper + Print Stylesheet

**Files:**
- Modify: `mirn_system_preview.html:12-42` (first `<script>` block — add Firebase init + auth)
- Modify: `mirn_system_preview.html:218-233` (`<style>` block — add print CSS)

**Interfaces:**
- Consumes: Firebase compat SDK (already loaded lines 8-11)
- Produces:
  - `window.mirnDb` — Firestore instance, available globally
  - `window.mirnAuth` — Firebase Auth instance
  - `window.withAuth(asyncFn)` — ensures auth, then calls `asyncFn(db)`, shows toast on error
  - `@media print` stylesheet that hides everything except `.pdf-paper`

- [ ] **Step 1: Add Firebase init + Anonymous Auth at top of first `<script>` block (line 12)**

Add immediately after `<script>` opening (before `showToast`):
```js
// Firebase singleton init
(function() {
  const cfg = {
    apiKey: "AIzaSyCgIRRJ1JUrevIS8JDBzVHuF5XmSCAsZxU",
    authDomain: "mirn-power-system.firebaseapp.com",
    projectId: "mirn-power-system",
    storageBucket: "mirn-power-system.firebasestorage.app",
    messagingSenderId: "567114559597",
    appId: "1:567114559597:web:8908dad67f7f10be854f64",
  };
  if (!firebase.apps.length) firebase.initializeApp(cfg);
  window.mirnDb = firebase.firestore();
  window.mirnAuth = firebase.auth();
  window._authReady = window.mirnAuth.signInAnonymously()
    .then(() => console.log('✓ Firebase Anonymous Auth OK'))
    .catch(err => console.error('Auth failed:', err));
})();

async function withAuth(fn) {
  try {
    await window._authReady;
    return await fn(window.mirnDb);
  } catch (err) {
    console.error('Firestore operation failed:', err);
    showToast('❌ خطأ في الاتصال بقاعدة البيانات: ' + err.message);
    throw err;
  }
}
```

- [ ] **Step 2: Add print stylesheet to `<style>` block**

Append to the existing `<style>` block before `</style>`:
```css
@media print {
  body > * { display: none !important; }
  .pdf-preview-modal { display: flex !important; position: static !important; background: white !important; }
  .pdf-preview-modal > div { border: none !important; box-shadow: none !important; max-width: 100% !important; max-height: none !important; overflow: visible !important; }
  .pdf-preview-modal .pdf-paper { display: block !important; }
  .pdf-preview-modal button { display: none !important; }
  .pdf-preview-modal .flex.justify-between.items-center.border-b { display: none !important; }
  .pdf-preview-modal .flex.justify-between.items-center.pt-2 { display: none !important; }
}
```

- [ ] **Step 3: Verify Anonymous Auth in browser console**

Open `mirn_system_preview.html` in browser, open DevTools console.
Expected: `✓ Firebase Anonymous Auth OK` logged. No errors.

- [ ] **Step 4: Refactor `triggerCloudSeed()` to use `withAuth()`**

Replace the try/catch body of `triggerCloudSeed()` (lines 159-196) so it calls `withAuth(async (db) => { ... })` instead of initializing Firebase again. Remove the duplicate `firebase.initializeApp()` and use `window.mirnDb`.

- [ ] **Step 5: Verify Cloud Seeder button works**

Click "تغذية السحابة الآن" button. Check Firebase Console → Firestore → `products` and `contacts` collections.
Expected: 6 products and 5 contacts appear in Firestore.

- [ ] **Step 6: Commit**
```bash
git add -A && git commit -m "feat: add Firebase auth init, withAuth wrapper, print stylesheet"
```

---

### Task 1: Firestore Data Loader — Load Collections on Page Init

**Files:**
- Modify: `mirn_system_preview.html` (end of second `<script>` block, near `calculatePosTotals(); renderDispatches(); renderExpenses();` at line 2666)

**Interfaces:**
- Consumes: `withAuth(fn)`, `window.mirnDb` from Task 0
- Produces:
  - `window.productsCache` — `Map<id, productObj>`
  - `window.contactsCache` — `Map<id, contactObj>`
  - `window.checksCache` — `Array<checkObj>`
  - `loadFirestoreData()` — async function that populates caches, populates DOM dropdowns and tables

- [ ] **Step 1: Implement `loadFirestoreData()` after the init calls**

The function:
1. Fetches `products`, `contacts`, `checks` collections from Firestore
2. Populates `window.productsCache`, `window.contactsCache`, `window.checksCache`
3. Rebuilds the inventory table rows from products data
4. Rebuilds customer `<option>` elements in `#customerSelect`, receipt modal customer info, and dispatch modal customer dropdown
5. Rebuilds check cards in `#checksList`

- [ ] **Step 2: Call `loadFirestoreData()` on page load**

Add to init block: `loadFirestoreData().catch(err => console.log('Offline mode — using hardcoded data'));`

- [ ] **Step 3: Verify data loads from Firestore**

After seeding (Task 0 Step 5), reload page. Inventory table, customer dropdowns, and check list should populate from Firestore data.
Expected: Products from Firestore appear in inventory table; contacts appear in dropdowns.

- [ ] **Step 4: Commit**
```bash
git add -A && git commit -m "feat: load Firestore data on page init, populate DOM from cache"
```

---

### Task 2: Sales POS — Invoice, Credit Note, Add Customer → Firestore + DOM

**Files:**
- Modify: `mirn_system_preview.html` — functions `processSale()`, `submitCreditNote()`, `submitAddContact()`

**Interfaces:**
- Consumes: `withAuth(fn)`, `window.mirnDb`, `window.contactsCache` from Task 0/1
- Produces:
  - `processSale()` writes to `sales` collection, decrements `products` stock, updates `contacts` balance, adds statement entry row to DOM
  - `submitCreditNote()` writes to `credit_notes` collection, increments `products` stock, decreases `contacts` balance, adds statement entry row
  - `submitAddContact()` writes to `contacts` collection, adds `<option>` to all customer dropdowns, updates `contactsCache`

- [ ] **Step 1: Rewrite `submitAddContact()` to write Firestore + update DOM**

```js
async function submitAddContact() {
  const name = document.getElementById('modalContactName')?.value.trim();
  const taxId = document.getElementById('modalContactTaxId')?.value.trim();
  if (!name || !taxId) { alert('...'); return; }

  await withAuth(async (db) => {
    const docRef = db.collection('contacts').doc();
    const contact = { id: docRef.id, name, taxId, type: 'customer', currentBalance: 0, debtWarningLimit: 50000, phone: '', address: '' };
    await docRef.set(contact);
    // Add to all customer dropdowns
    ['customerSelect', 'modalDispCustomer'].forEach(selId => {
      const sel = document.getElementById(selId);
      if (sel) { const opt = new Option(name + ' (رصيد: ₪0)', docRef.id); sel.add(opt); }
    });
    window.contactsCache?.set(docRef.id, contact);
  });
  closeAddContactModal();
  showToast('✅ تمت إضافة جهة الاتصال: ' + name + ' بنجاح!');
}
```

- [ ] **Step 2: Rewrite `processSale()` to write Firestore + update DOM**

Must: (1) build sale object from current form state, (2) write to `sales` collection, (3) decrement product stock in `products` doc, (4) increment customer balance in `contacts` doc (by debt amount), (5) add row to statements table, (6) if check payment, add check card. Use `firebase.firestore.FieldValue.increment()` for atomic updates.

- [ ] **Step 3: Rewrite `submitCreditNote()` to write Firestore + update DOM**

Must: (1) write to `credit_notes`, (2) increment product stock via `FieldValue.increment()`, (3) decrement customer balance via `FieldValue.increment(-amount)`, (4) add credit note row to statements table.

- [ ] **Step 4: Verify — add a new customer, then issue an invoice to that customer**

1. Click "زبون جديد", fill form, submit. Check: new option appears in dropdown + Firestore `contacts` collection has new doc.
2. Select new customer, add items, click "إصدار فاتورة". Check: Firestore `sales` has new doc, `products` stock decremented, `contacts` balance updated.

Expected: All 3 Firestore writes succeed; DOM updates immediately.

- [ ] **Step 5: Verify — issue a credit note**

Click "إرجاع وإصدار זיכוי", fill amount, submit. Check: Firestore `credit_notes` has new doc, product stock incremented, customer balance decreased.

- [ ] **Step 6: Commit**
```bash
git add -A && git commit -m "feat: sales POS — invoice, credit note, add customer write to Firestore"
```

---

### Task 3: Inventory — Add Product + Purchase Intake → Firestore + DOM

**Files:**
- Modify: `mirn_system_preview.html` — functions `submitAddProduct()`, `submitPurchaseModal()`, `previewPurchasePdf()`

**Interfaces:**
- Consumes: `withAuth(fn)`, `window.mirnDb`, `window.productsCache` from Task 0/1
- Produces:
  - `submitAddProduct()` writes to `products` collection, appends row to inventory table, adds `<option>` to product dropdowns
  - `submitPurchaseModal()` writes to `purchases` collection, updates `products` stock via `FieldValue.increment()`, updates `contacts` (supplier) balance
  - `previewPurchasePdf()` opens the purchase PDF modal with printable A4 view

- [ ] **Step 1: Rewrite `submitAddProduct()` to write Firestore + update DOM**

Collect all fields from modal (`modalProdNameAr`, `modalProdSku`, `modalProdPrice`, etc.), write to `products` collection, append `<tr>` to inventory table with matching `id="row-{docId}"` structure, add `<option>` to `#prodSelect` and `#modalPurchaseProduct`.

- [ ] **Step 2: Rewrite `submitPurchaseModal()` to add Firestore writes**

The existing function already updates DOM (lines 1877-1963). Add after DOM updates:
1. Write purchase document to `purchases` collection
2. Update product stock: `db.collection('products').doc(prodId).update({ currentStock: firebase.firestore.FieldValue.increment(convertedStock) })`
3. If not immediate payment, update supplier balance: `db.collection('contacts').doc(suppId).update({ currentBalance: firebase.firestore.FieldValue.increment(total) })`

- [ ] **Step 3: Implement real PDF preview for purchase — add `pdf-preview-modal` class + `pdf-paper` class**

Create a new modal (or modify existing `previewPurchasePdf()` alert) with an A4 white paper layout matching the delivery note PDF modal style. Add class `pdf-preview-modal` to the modal container and `pdf-paper` to the white paper div. Add a print button that calls `window.print()`.

- [ ] **Step 4: Verify — add a new product, then do a purchase intake for it**

1. Click "إضافة صنف جديد", fill form, submit. Check: Firestore `products` has new doc, inventory table has new row, product dropdowns have new option.
2. Open purchase modal, select the new product, fill qty and cost, submit. Check: Firestore `purchases` has new doc, `products` stock updated, supplier balance updated.

Expected: All Firestore writes succeed; DOM updates immediately.

- [ ] **Step 5: Verify PDF preview and print**

Click PDF button on a purchase row. The A4 preview modal opens. Click print. `window.print()` fires showing only the A4 document.
Expected: Print dialog opens with clean A4 layout.

- [ ] **Step 6: Commit**
```bash
git add -A && git commit -m "feat: inventory — add product, purchase intake write to Firestore + PDF print"
```

---

### Task 4: Account Statement — Receipt Form Customer Selector + Firestore + PDF

**Files:**
- Modify: `mirn_system_preview.html` — receipt modal HTML (lines 2671-2738), `submitReceiptModal()`, `updateReceiptProjectedBalance()`, statement PDF export

**Interfaces:**
- Consumes: `withAuth(fn)`, `window.mirnDb`, `window.contactsCache` from Task 0/1
- Produces:
  - Receipt modal has a customer `<select>` dropdown replacing the hardcoded "شركة البراق" text
  - `submitReceiptModal()` writes to `receipts` collection, updates `contacts` balance via `FieldValue.increment(-amount)`, updates DOM
  - Statement PDF export button uses `window.print()` on a generated A4 layout

- [ ] **Step 1: Add customer dropdown to receipt modal**

Replace the hardcoded customer info div (lines 2682-2685) with a `<select>` dropdown populated from `window.contactsCache`. On change, update the displayed balance and recalculate projected balance.

- [ ] **Step 2: Rewrite `submitReceiptModal()` to write Firestore + update DOM**

Must: (1) get selected customer from new dropdown, (2) write receipt to `receipts` collection, (3) update customer balance: `FieldValue.increment(-amount)`, (4) if check payment, write to `checks` collection, (5) add row to statement table, (6) add check card to checks list if applicable.

- [ ] **Step 3: Implement statement PDF export button**

Add a "تصدير PDF" button to the statements tab toolbar. On click, generate an A4 layout showing the statement table for the selected customer in a `.pdf-preview-modal` container, then call `window.print()`.

- [ ] **Step 4: Verify — change customer in receipt modal, submit receipt**

1. Open receipt modal, change customer dropdown to a different customer. Check: balance updates dynamically.
2. Submit receipt. Check: Firestore `receipts` has new doc, `contacts` balance decreased, statement table has new row.

Expected: Customer selector works; Firestore writes succeed.

- [ ] **Step 5: Verify PDF export**

Click PDF export on statement page. Print dialog opens with statement A4 layout.
Expected: Clean A4 printout of statement data.

- [ ] **Step 6: Commit**
```bash
git add -A && git commit -m "feat: account statement — customer selector, receipt Firestore, PDF export"
```

---

### Task 5: Checks — Image Upload Fields + Firestore + Print/Preview

**Files:**
- Modify: `mirn_system_preview.html` — check modal HTML (lines 3323-3395), `submitNewCheck()`, check list rendering

**Interfaces:**
- Consumes: `withAuth(fn)`, `window.mirnDb`, `window.checksCache` from Task 0/1
- Produces:
  - Check modal has two `<input type="file">` fields: check image + ID photo
  - `submitNewCheck()` writes to `checks` collection (images stored as base64 data URLs), updates DOM check list
  - Each check card has a "معاينة / طباعة" button that opens an A4 print-ready preview

- [ ] **Step 1: Add image upload fields to check modal**

After the due date field (line 3385), add two file inputs:
```html
<div class="grid grid-cols-2 gap-3">
  <div>
    <label class="block text-gray-400 mb-1">صورة الشيك / תמונת השיק</label>
    <input type="file" id="modalCheckImage" accept="image/*" class="w-full bg-[#25252D] border border-[#33333E] rounded-xl px-3 py-2 text-white text-xs outline-none file:bg-[#C5A059] file:text-black file:border-0 file:rounded-lg file:px-3 file:py-1 file:text-xs file:font-bold">
  </div>
  <div>
    <label class="block text-gray-400 mb-1">صورة هوية الساحب / תעודת זהות</label>
    <input type="file" id="modalCheckIdImage" accept="image/*" class="w-full bg-[#25252D] border border-[#33333E] rounded-xl px-3 py-2 text-white text-xs outline-none file:bg-[#C5A059] file:text-black file:border-0 file:rounded-lg file:px-3 file:py-1 file:text-xs file:font-bold">
  </div>
</div>
```

- [ ] **Step 2: Rewrite `submitNewCheck()` to write Firestore + store images as base64**

Read files via `FileReader.readAsDataURL()`. Write check document to `checks` collection including `checkImageBase64` and `idImageBase64` fields. Update `window.checksCache`. Add check card to DOM with print button.

- [ ] **Step 3: Add print/preview button to each check card**

In the check card HTML template (both in `submitNewCheck()` and `submitReceiptModal()`), add a button:
```html
<button onclick="previewCheckPdf('CHECK_ID')" class="px-3 py-1.5 rounded-lg border border-[#C5A059] text-[#C5A059] hover:bg-[#C5A059]/10 font-bold flex items-center gap-1">
  📄 معاينة
</button>
```

- [ ] **Step 4: Implement `previewCheckPdf(checkId)` function**

Creates an A4 modal with `.pdf-preview-modal` and `.pdf-paper` classes showing: check number, amount, bank details, drawer name, due date, check image (if available), ID image (if available). Print button calls `window.print()`.

- [ ] **Step 5: Verify — add a new check with images, then preview/print it**

1. Open add check modal, fill fields, attach check photo + ID photo, submit. Check: Firestore `checks` has new doc with base64 image data, DOM check list has new card.
2. Click "معاينة" on the new check card. A4 preview opens with images. Click print.

Expected: Check saved to Firestore with images; print dialog shows A4 layout with images.

- [ ] **Step 6: Commit**
```bash
git add -A && git commit -m "feat: checks — image upload, Firestore write, print/preview"
```

---

### Task 6: Fleet — Dispatches + Expenses → Firestore + Print

**Files:**
- Modify: `mirn_system_preview.html` — functions `submitNewDispatch()`, `advanceDispatchStatus()`, `confirmCompleteDelivery()`, `submitNewExpense()`, `printDeliveryNote()`, `printExpenseVoucher()`, `submitAddVehicle()`

**Interfaces:**
- Consumes: `withAuth(fn)`, `window.mirnDb` from Task 0
- Produces:
  - `submitNewDispatch()` writes to `dispatches` collection + updates `dispatchesData` array + re-renders
  - `advanceDispatchStatus()` updates status in `dispatches` doc
  - `confirmCompleteDelivery()` updates status + odometer in `dispatches` doc
  - `submitNewExpense()` writes to `expenses` collection
  - `submitAddVehicle()` writes to `vehicles` collection + updates DOM
  - `printDeliveryNote()` calls `window.print()` with scoped print (add `pdf-preview-modal` class to `#deliveryNotePdfModal`)
  - `printExpenseVoucher()` calls `window.print()` with scoped print (add `pdf-preview-modal` class to `#expenseVoucherPdfModal`)

- [ ] **Step 1: Add `pdf-preview-modal` class to existing PDF modals**

Add class `pdf-preview-modal` to `#deliveryNotePdfModal` (line 2999) and `#expenseVoucherPdfModal` (line 3215). Add class `pdf-paper` to their inner white A4 paper divs.

- [ ] **Step 2: Rewrite `printDeliveryNote()` and `printExpenseVoucher()` to use `window.print()`**

Replace `alert(...)` with `window.print()`. Do NOT close the modal after printing — the user might want to print again.

- [ ] **Step 3: Add Firestore writes to `submitNewDispatch()`**

After creating the `newDispatch` object and before `dispatchesData.unshift(newDispatch)`, add:
```js
await withAuth(async (db) => {
  await db.collection('dispatches').doc(newDispatch.id).set(newDispatch);
});
```
Make the function `async`.

- [ ] **Step 4: Add Firestore updates to `advanceDispatchStatus()` and `confirmCompleteDelivery()`**

`advanceDispatchStatus`: update `dispatches` doc status field.
`confirmCompleteDelivery`: update `dispatches` doc status + odometer reading.

- [ ] **Step 5: Add Firestore writes to `submitNewExpense()`**

Write expense to `expenses` collection. Make function `async`.

- [ ] **Step 6: Rewrite `submitAddVehicle()` to write Firestore + update DOM**

Write vehicle to `vehicles` collection. Add truck to dispatch and expense vehicle dropdowns.

- [ ] **Step 7: Verify — create dispatch, advance to delivered, print delivery note**

1. Create new dispatch. Check: Firestore `dispatches` has new doc.
2. Click "بدء النقل" then "تأكيد التسليم". Check: Firestore doc updated.
3. Click "معاينة سند الإرسالية A4 PDF", then "طباعة". Print dialog opens.

Expected: All Firestore writes succeed; print dialog shows clean A4.

- [ ] **Step 8: Verify — create expense, preview and print voucher**

1. Create new expense. Check: Firestore `expenses` has new doc.
2. Click "معاينة سند صرف A4 PDF", then "طباعة". Print dialog opens.

Expected: Expense saved to Firestore; print shows A4 voucher.

- [ ] **Step 9: Commit**
```bash
git add -A && git commit -m "feat: fleet — dispatches, expenses, vehicles write to Firestore + real print"
```

---

### Task 7: Final Integration — Push to GitHub + Verification Pass

**Files:**
- Modify: `mirn_system_preview.html` (any remaining fixes found during integration testing)

**Interfaces:**
- Consumes: All prior tasks completed
- Produces: Fully working HTML preview committed and pushed to GitHub

- [ ] **Step 1: Full integration test — run through every form in sequence**

1. Cloud Seeder → verify Firestore
2. Add customer → verify dropdown + Firestore
3. Issue invoice → verify Firestore + DOM
4. Issue credit note → verify Firestore + DOM
5. Add product → verify table + Firestore
6. Purchase intake → verify Firestore + DOM
7. Purchase PDF → verify print
8. Receipt with customer change → verify Firestore
9. Statement PDF → verify print
10. Add check with images → verify Firestore
11. Check preview/print → verify print
12. New dispatch → verify Firestore
13. Dispatch lifecycle → verify Firestore
14. Delivery note print → verify print
15. New expense → verify Firestore
16. Expense voucher print → verify print
17. Add vehicle → verify Firestore

- [ ] **Step 2: Fix any issues found during integration**

- [ ] **Step 3: Commit and push to GitHub**
```bash
git add -A && git commit -m "feat: complete HTML preview Firestore integration — all forms functional"
git push origin master
```
