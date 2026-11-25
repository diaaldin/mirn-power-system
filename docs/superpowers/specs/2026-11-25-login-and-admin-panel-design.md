# Login Page & Super Admin Panel — Design Document

**Date:** 2026-11-25  
**Target Files:** `mirn_system_preview.html`, `firestore.rules`  
**Firebase Project:** `mirn-power-system`

---

## 1. Intent & Why

Currently `mirn_system_preview.html` auto-signs in anonymously (`signInAnonymously()`), meaning anyone who opens the URL gets full access to every page and record.  
This feature adds **authenticated access control** and a **Super Admin Panel** so that:
- Only staff accounts created by the Super Admin (with assigned passwords and roles) can log in and use the system.
- Only the single **Super Admin** can open and manage the Admin Panel.
- The Super Admin can enable/disable any page in real time, control which roles can access which pages, customize the locked-page message (*"Call the admin to help you"*), and audit system activity.

---

## 2. Approaches Considered

### User Management & Passwords
- **Approach 1 (Chosen): Pure Browser + Firebase Auth & Firestore**
  - *How:* Use Firebase Email/Password Auth. Create new staff accounts from the Admin Panel via a secondary Firebase app instance (`firebase.initializeApp(cfg, 'SecondaryAdminApp')`) so the Super Admin stays logged in. Store role, active status, and metadata in Firestore `users/{uid}`. "Removing" a user marks `active: false` (and `removed: true`) in Firestore, immediately blocking login and data access while preserving historical invoices/receipts. Password updates for existing users trigger Firebase's password-reset email.
  - *Trade-off:* Zero backend server needed; works in the single-file web app. Permanent deletion from Firebase Auth or silent password overwrite of an existing user is deferred unless a Cloud Function/Node Admin SDK backend is added later.
- **Approach 2 (Rejected): Custom Node / Cloud Functions Admin SDK Backend**
  - *Trade-off:* Allows hard-deleting Auth users and silently overwriting passwords, but requires deploying and securing a backend with a service-account key.

### Super Admin Registration
- **Option A (Chosen): Firebase Console Creation + Allowlisted Bootstrap**
  - *How:* Enable Email/Password auth in Firebase Console → Authentication, create the single Super Admin email/password there, and configure the Super Admin's email in the app config & `firestore.rules`. On first login, the app creates the `users/{uid}` doc with `role: 'super_admin'`. `firestore.rules` strictly forbids any other document from having `role == 'super_admin'`.
  - *Trade-off:* Eliminates any race condition where an unauthorized visitor claims Super Admin before setup.
- **Option B (Rejected): In-app One-Time Setup Form**
  - *Trade-off:* Anyone visiting the URL before setup completes could see the setup screen.

---

## 3. Core Architecture & User Flows

### A. Login Gate (Replaces Anonymous Auth)
- On page load, the main app shell (`#appShell`) is hidden and a dark/gold branded **Login Screen** (`#loginView`) is shown until `onAuthStateChanged` confirms a signed-in user whose `users/{uid}` profile has `active === true`.
- **No public Sign-Up / Register button.**
- Fields: Email (or username) + Password + Sign In button + error banner.
- If a signed-in user has `active === false` (disabled/removed) or has no profile (and is not the allowlisted Super Admin), they are signed out immediately and shown an *"Account disabled — contact the Super Admin"* message.
- Header bar displays the signed-in user's name, role badge, a **Logout** button, and (for `super_admin` only) the **Admin Panel** tab button.

### B. Exclusive `super_admin` Role & Staff Roles
- **`super_admin`** (exclusive): Only the allowlisted Super Admin account can hold this role. Never appears in the "Add User" role dropdown. Can access all pages (even inactive ones, with a preview banner) and the Admin Panel.
- **Staff Roles** (assignable by Super Admin):
  - `manager` (Manager / مدير)
  - `sales` (Sales / مبيعات)
  - `accountant` (Accountant / محاسب)
  - `warehouse` (Warehouse / مستودع)
  - `driver` (Driver / سائق)

### C. Admin Panel Tab (`#view-admin`, visible ONLY to `super_admin`)
1. **User Management:**
   - **Add User form:** Full Name, Email, Initial Password (min 6 chars), Role dropdown (staff roles only). Creates Auth user via secondary Firebase app, writes `users/{uid}` in Firestore, signs out secondary app, refreshes list, and logs an audit entry.
   - **Users Table:** Lists all staff users (Name, Email, Role selector to change role live, Status badge Active/Disabled, Actions: **Toggle Active/Disable**, **Send Password Reset Email**, **Remove** — soft-removes & hides from active list while keeping audit history).
2. **Page Access & Maintenance Control:**
   - **Global Maintenance Mode Toggle:** Master switch that locks all 6 operational pages for all non-`super_admin` users.
   - **Per-Page Controls** for the 6 pages (`dashboard`, `pos`, `inventory`, `statements`, `checks`, `fleet`):
     - **Active / Inactive Toggle** per page.
     - **Allowed Roles Checkboxes** per page (which staff roles can view/use that page when active).
   - **Locked Screen Message Editor:**
     - Global default message (default: `"اتصل بالمسؤول لمساعدتك / Call the admin to help you"`).
     - Optional per-page custom message override.
     - Admin Support Phone / WhatsApp number field (shown as a call/contact button on the locked screen).
3. **Audit Log Feed:**
   - Read-only chronological feed of recent events from `audit_logs` (logins, user added/disabled/removed, role changes, page toggles, message updates).

### D. Locked / Inactive Page View (`#view-locked`)
- Whenever a non-`super_admin` user clicks or is routed to a page where:
  - Global Maintenance Mode is ON, **or**
  - That page's Active toggle is OFF, **or**
  - Their role is not in that page's `allowedRoles`:
- They are directed to `#view-locked`, displaying the lock icon, page name, the **Admin-configured message** (per-page override if set, otherwise global message), and an optional "Call / WhatsApp Admin" link if configured.
- Real-time Firestore `onSnapshot` listener on `app_config/access_control` and `users/{uid}` ensures that if the Super Admin disables a page or user while they are logged in, the UI reacts immediately.

---

## 4. Firestore Data Model & Security Rules

- **`users/{uid}`**:
  - `{ uid, name, email, role, active: boolean, removed: boolean, createdAt, updatedAt }`
- **`app_config/access_control`**:
  - `{ maintenanceMode: boolean, globalBlockedMessage: string, adminPhone: string, pages: { [pageKey]: { active: boolean, allowedRoles: string[], customMessage: string } }, updatedAt }`
- **`audit_logs/{logId}`**:
  - `{ action, actorUid, actorEmail, target, details, timestamp }`

### `firestore.rules` Updates
- Helper `isSuperAdmin()`: `isAuthenticated() && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.active == true`.
- Helper `isActiveUser()`: `isAuthenticated() && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.active == true`.
- `/users/{userId}`:
  - `read`: `isSuperAdmin() || (isAuthenticated() && request.auth.uid == userId)`
  - `create`: `isSuperAdmin()` (with `request.resource.data.role != 'super_admin'`) OR allowlisted Super Admin email bootstrapping their own `super_admin` doc.
  - `update`: `isSuperAdmin()` (cannot change `role` to `'super_admin'` on other users).
  - `delete`: `false`.
- `/app_config/{docId}`:
  - `read`: `isAuthenticated()`
  - `write`: `isSuperAdmin()`
- `/audit_logs/{logId}`:
  - `read`: `isSuperAdmin()`
  - `create`: `isAuthenticated()`
  - `update, delete`: `false`
- Existing operational collections (`products`, `contacts`, `sales`, etc.): keep `isAuthenticated()` (and optionally check active user status).

---

## 5. Goals, Non-Goals & Constraints

- **Goals:** Secure login gate, exclusive `super_admin`, full user/role lifecycle in the Admin Panel, real-time page active/inactive toggles with customizable blocked message, audit log.
- **Non-Goals:** Public user self-registration, backend Node/Cloud Functions deployment, multi-super-admin delegation.
- **Constraints:** Bilingual Arabic/English/Hebrew UI matching existing dark/gold theme (`#121214`, `#1E1E24`, `#C5A059`); single-file HTML/JS + `firestore.rules`.
- **Left to Builder/Plan:** Exact DOM IDs, Firestore error handling, initial `app_config/access_control` seeding on Super Admin's first login, and real-time `onSnapshot` listeners.
