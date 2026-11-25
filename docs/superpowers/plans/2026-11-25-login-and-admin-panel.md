# Login Page & Super Admin Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace anonymous sign-in in `mirn_system_preview.html` with an Email/Password Login Gate, an exclusive `super_admin` role (`dia81994@gmail.com`), and a real-time Admin Panel for managing users (passwords, roles, active status), per-page active/inactive toggles with customizable locked messages, and an audit log.

**Architecture:** `mirn_system_preview.html` hides `#appShell` behind `#loginView` until Firebase `onAuthStateChanged` verifies an active user profile in Firestore `users/{uid}`. A secondary Firebase app instance (`SecondaryAdminApp`) lets the Super Admin create staff accounts with passwords without logging out. Real-time Firestore `onSnapshot` listeners on `users/{uid}` and `app_config/access_control` enforce page toggles, role permissions, maintenance mode, and account disabling immediately. `firestore.rules` enforces `super_admin` exclusivity server-side.

**Tech Stack:** Vanilla HTML/JS, Tailwind CSS (CDN), Firebase Web SDK 10.8.0 (compat: Auth + Firestore), Cloud Firestore Security Rules.

**Spec:** [docs/superpowers/specs/2026-11-25-login-and-admin-panel-design.md](../specs/2026-11-25-login-and-admin-panel-design.md)

## Global Constraints

- **Target files:** `mirn_system_preview.html` and `firestore.rules`.
- **Firebase project:** `mirn-power-system`.
- **Exclusive Super Admin email:** `dia81994@gmail.com` — the only account permitted to hold `role: 'super_admin'` and access `#view-admin`.
- **Staff roles (assignable in Admin Panel):** `manager`, `sales`, `accountant`, `warehouse`, `driver` (`super_admin` must NEVER appear in the Add/Edit User role dropdown).
- **No public sign-up:** `#loginView` only provides Sign In (Email + Password).
- **Default locked message:** `"اتصل بالمسؤول لمساعدتك / Call the admin to help you"`.
- **UI theme & copy:** Match existing dark/gold theme (`#121214`, `#1E1E24`, `#25252D`, `#C5A059`), bilingual Arabic/English/Hebrew labels.

## Review Focus

1. **Disabled/removed user with cached Auth session:** If an admin disables or soft-removes a user while that user has a valid Firebase Auth token or is mid-session, the `onSnapshot` listener on `users/{uid}` (and login check) must immediately sign them out and show `#loginView` with an account-disabled error.
2. **Secondary Firebase app cleanup on error:** If `createUserWithEmailAndPassword` fails (e.g., email already in use or weak password), the secondary app must still be cleaned up / signed out cleanly and never affect `window.mirnAuth` (the Super Admin's active session).
3. **Privilege escalation prevention:** Neither the UI nor `firestore.rules` may allow any non-allowlisted user to create or update a document with `role: 'super_admin'`, or modify `app_config/access_control`.
4. **Live page toggle mid-session:** If the Super Admin toggles a page OFF (or enables Maintenance Mode) while a staff user is currently viewing that page, `onSnapshot` on `app_config/access_control` must immediately redirect that user to `#view-locked` displaying the updated message.
5. **First-time bootstrap race:** On `dia81994@gmail.com`'s very first login, `users/{uid}` and `app_config/access_control` do not exist yet; the bootstrap routine must create both cleanly before `loadFirestoreData()` and `onSnapshot` listeners attach, without throwing permission or null-reference errors.

---

### Task 0: Update Firestore Security Rules for `super_admin`, `users`, `app_config`, and `audit_logs`

**Files:**
- Modify: `firestore.rules:137-143`
- Test: `node` / Firebase rules syntax check (or `firebase deploy --only firestore:rules` if Firebase CLI is logged in)

**Interfaces:**
- Produces Firestore rules enforcing:
  - `isSuperAdmin()` helper checking `users/{request.auth.uid}.data.role == 'super_admin'` and `active == true`
  - `/users/{userId}`: allowlisted `dia81994@gmail.com` can bootstrap own `super_admin` doc; only `isSuperAdmin()` can create/update staff docs (`role != 'super_admin'`)
  - `/app_config/{docId}`: readable by authenticated users, writable only by `isSuperAdmin()`
  - `/audit_logs/{logId}`: creatable by authenticated users, readable only by `isSuperAdmin()`, immutable

- [ ] **Step 1: Add `isSuperAdmin()`, `isActiveUser()`, and `isAllowlistedSuperAdmin()` helpers in `firestore.rules`**

Add helper functions right after `isAuthenticated()` in `firestore.rules`:
- `isAllowlistedSuperAdmin()`: `isAuthenticated() && request.auth.token.email == 'dia81994@gmail.com'`
- `isSuperAdmin()`: `isAuthenticated() && exists(/databases/$(database)/documents/users/$(request.auth.uid)) && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'super_admin' && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.active == true`
- `isActiveUser()`: `isAuthenticated() && exists(/databases/$(database)/documents/users/$(request.auth.uid)) && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.active == true`

- [ ] **Step 2: Replace `/users/{userId}` rule and add `/app_config/{docId}` & `/audit_logs/{logId}` rules**

In `firestore.rules:137-143`:
- `/users/{userId}`:
  - `allow read: if isSuperAdmin() || (isAuthenticated() && request.auth.uid == userId);`
  - `allow create: if (isAllowlistedSuperAdmin() && request.auth.uid == userId && request.resource.data.role == 'super_admin') || (isSuperAdmin() && request.resource.data.role != 'super_admin');`
  - `allow update: if isSuperAdmin() && (userId == request.auth.uid || request.resource.data.role != 'super_admin');`
  - `allow delete: if false;`
- `/app_config/{docId}`:
  - `allow read: if isAuthenticated();`
  - `allow write: if isSuperAdmin();`
- `/audit_logs/{logId}`:
  - `allow read: if isSuperAdmin();`
  - `allow create: if isAuthenticated();`
  - `allow update, delete: if false;`

- [ ] **Step 3: Verify `firestore.rules` syntax and structure**

Run: `Select-String -Pattern "isSuperAdmin|app_config|audit_logs|dia81994@gmail.com" firestore.rules`
Expected: All 4 patterns present with balanced braces. (Note: user will deploy rules via `firebase deploy --only firestore:rules` or Firebase Console Rules tab.)

- [ ] **Step 4: Commit**

```bash
git add firestore.rules && git commit -m "feat(security): add super_admin, app_config, and audit_logs firestore rules"
```

---

### Task 1: Replace Anonymous Auth with Login Gate (`#loginView`) & Super Admin Bootstrap

**Files:**
- Modify: `mirn_system_preview.html:12-41` (Firebase init + `withAuth`)
- Modify: `mirn_system_preview.html:267-272` (`<body>` wrapper: add `#loginView` and wrap main container in `#appShell`)
- Modify: `mirn_system_preview.html:455-477` (header: replace `#userRoleSelect` simulated dropdown with `#headerUserInfo` + Logout button)
- Modify: `mirn_system_preview.html:4050-4056` (remove unconditional `loadFirestoreData()` at bottom)

**Interfaces:**
- Consumes: Firebase Auth & Firestore SDKs
- Produces:
  - `window.SUPER_ADMIN_EMAIL = 'dia81994@gmail.com'`
  - `window.currentUserProfile` — `{ uid, name, email, role, active, removed }`
  - `window.withAuth(fn)` — awaits active authenticated user before running `fn(window.mirnDb)`
  - `handleLoginSubmit(event)` — calls `signInWithEmailAndPassword`
  - `handleLogout()` — signs out and returns to `#loginView`

- [ ] **Step 1: Replace `signInAnonymously()` block in `<head>` `<script>` with `onAuthStateChanged` gate**

Remove `signInAnonymously()`. Define `window.SUPER_ADMIN_EMAIL = 'dia81994@gmail.com'`, `window.currentUserProfile = null`, and a deferred auth-ready promise resolved only when a valid active user is authenticated. Keep `withAuth(fn)` checking `window.mirnAuth.currentUser`.

- [ ] **Step 2: Add `#loginView` HTML and wrap the existing app container in `#appShell` (`hidden`)**

Right inside `<body>` (before `<div class="max-w-7xl mx-auto space-y-6">`):
- Add `#loginView` (centered dark/gold card with M.I.R.N POWER branding, Email input `#loginEmail`, Password input `#loginPassword`, error banner `#loginError`, Submit button `#btnLoginSubmit`, NO sign-up link).
- Wrap the existing `<div class="max-w-7xl mx-auto space-y-6">` in `<div id="appShell" class="hidden">...</div>`.

- [ ] **Step 3: Replace simulated `#userRoleSelect` in header with authenticated user badge & Logout button**

In header (`mirn_system_preview.html:457-466`), replace `#userRoleSelect` with:
- `#headerUserName` + `#headerUserRoleBadge`
- Logout button calling `handleLogout()`

- [ ] **Step 4: Implement `initAuthGate()`, `bootstrapSuperAdminIfNeeded(user)`, `handleLoginSubmit(e)`, `handleLogout()`, and `writeAuditLog(action, target, details)`**

- On `onAuthStateChanged(user)`:
  - If `!user`: hide `#appShell`, show `#loginView`, unsubscribe active snapshots.
  - If `user`: fetch `users/{user.uid}`.
    - If doc doesn't exist AND `user.email.toLowerCase() === window.SUPER_ADMIN_EMAIL`: create `users/{user.uid}` with `{ uid: user.uid, name: 'Super Admin', email: user.email, role: 'super_admin', active: true, removed: false, createdAt: serverTimestamp() }`, and ensure `app_config/access_control` exists with defaults.
    - If doc doesn't exist (and not Super Admin) OR `doc.active !== true` OR `doc.removed === true`: sign out immediately and display `#loginError` (*"الحساب غير مفعل أو غير مصرح له — تواصل مع المسؤول / Account disabled or unauthorized"*).
    - Otherwise: set `window.currentUserProfile`, update header badge, show `#appShell`, hide `#loginView`, attach real-time listeners (Task 2), log `'login'` to `audit_logs`, and call `loadFirestoreData()`.

- [ ] **Step 5: Verify HTML tag balance and script syntax**

Run: `node -e "const fs=require('fs'),h=fs.readFileSync('mirn_system_preview.html','utf8'); console.log('loginView:',h.includes('id=\"loginView\"'),'appShell:',h.includes('id=\"appShell\"'),'noAnon:',!h.includes('signInAnonymously'))"`
Expected: `loginView: true appShell: true noAnon: true`

- [ ] **Step 6: Commit**

```bash
git add mirn_system_preview.html && git commit -m "feat(auth): replace anonymous auth with email/password login gate and super_admin bootstrap"
```

---

### Task 2: Page Access Guard, Locked Screen (`#view-locked`), & Real-Time `onSnapshot` Listeners

**Files:**
- Modify: `mirn_system_preview.html` (Nav tabs, `#view-locked` section after `</nav>`, `switchTab()`, real-time listeners)

**Interfaces:**
- Consumes: `window.currentUserProfile`, `window.mirnDb`, `window.SUPER_ADMIN_EMAIL` from Task 1
- Produces:
  - `window.appAccessConfig` — live object synced from `app_config/access_control`
  - `canAccessPage(pageKey)` — returns `{ allowed: boolean, reason: string, message: string }`
  - `applyAccessControlToNav()` — updates nav tab badges/visibility and enforces access on `currentTab`
  - `switchTab(tab)` — checks `canAccessPage(tab)` before revealing `#view-${tab}`; routes non-super-admins to `#view-locked` when blocked

- [ ] **Step 1: Add `#view-locked` section right after `</nav>`**

Create `<section id="view-locked" class="hidden ...">` with:
- Lock icon, `#lockedPageTitle`, `#lockedMessageText` (defaults to `"اتصل بالمسؤول لمساعدتك / Call the admin to help you"`), and `#lockedAdminContact` (clickable `tel:` / WhatsApp link when `adminPhone` is set).

- [ ] **Step 2: Define `DEFAULT_ACCESS_CONFIG` and `canAccessPage(pageKey)`**

- `OPERATIONAL_PAGES = ['dashboard', 'pos', 'inventory', 'statements', 'checks', 'fleet']`
- `STAFF_ROLES = ['manager', 'sales', 'accountant', 'warehouse', 'driver']`
- `canAccessPage(pageKey)`:
  - If `window.currentUserProfile?.role === 'super_admin'`: always `{ allowed: true }` (if page is inactive or maintenance mode is on, show a small amber preview banner, never block `super_admin`).
  - If `pageKey === 'admin'`: `{ allowed: false, message: ... }` for non-`super_admin`.
  - If `appAccessConfig.maintenanceMode === true`: `{ allowed: false, message: appAccessConfig.globalBlockedMessage }`.
  - Check `pageCfg = appAccessConfig.pages[pageKey]`:
    - If `!pageCfg.active`: `{ allowed: false, message: pageCfg.customMessage || appAccessConfig.globalBlockedMessage }`.
    - If `!pageCfg.allowedRoles.includes(window.currentUserProfile.role)`: `{ allowed: false, message: pageCfg.customMessage || appAccessConfig.globalBlockedMessage }`.
    - Otherwise `{ allowed: true }`.

- [ ] **Step 3: Update `switchTab(tab)` and add `applyAccessControlToNav()` + `startAccessListeners()`**

- Update `switchTab(tab)` to include `'admin'` and `'locked'` in the view-hiding loop, track `window.currentTab = tab`, and check `canAccessPage(tab)`. If `!allowed`, show `#view-locked` populated with `message` and `adminPhone`.
- `startAccessListeners()`:
  - `onSnapshot` on `users/{uid}`: if `active !== true` or `removed === true`, immediately `mirnAuth.signOut()` and show error on `#loginView`. If role changed, update `window.currentUserProfile` and call `applyAccessControlToNav()`.
  - `onSnapshot` on `app_config/access_control`: update `window.appAccessConfig`, call `applyAccessControlToNav()`, and re-check `window.currentTab` (redirecting to `#view-locked` immediately if the current page was just turned off).

- [ ] **Step 4: Verify JS syntax and required functions**

Run: `node -e "const fs=require('fs'),h=fs.readFileSync('mirn_system_preview.html','utf8'); console.log('locked:',h.includes('id=\"view-locked\"'),'canAccess:',h.includes('function canAccessPage'),'onSnapshot:',h.includes('onSnapshot'))"`
Expected: `locked: true canAccess: true onSnapshot: true`

- [ ] **Step 5: Commit**

```bash
git add mirn_system_preview.html && git commit -m "feat(rbac): add page access guard, locked view, and real-time onSnapshot listeners"
```

---

### Task 3: Admin Panel Tab (`#view-admin`) & User Management (Add, Password, Role, Disable, Reset, Soft-Remove)

**Files:**
- Modify: `mirn_system_preview.html` (Nav tab `#tab-admin`, `#view-admin` HTML section, admin user management JS)

**Interfaces:**
- Consumes: `window.currentUserProfile`, `window.mirnDb`, `window.mirnAuth`, `writeAuditLog()` from Tasks 1–2
- Produces:
  - `loadAdminUsers()` — loads non-removed users from `users` collection and renders `#adminUsersTableBody`
  - `adminCreateUser()` — creates Firebase Auth user via secondary Firebase app (`SecondaryAdminApp`) without signing out `super_admin`, writes `users/{uid}`, signs out secondary app in `finally`
  - `adminUpdateUserRole(uid, newRole)` — updates `role` in `users/{uid}` (rejects `'super_admin'`)
  - `adminToggleUserActive(uid, nextActive)` — toggles `active` boolean in `users/{uid}`
  - `adminSendPasswordReset(email)` — calls `window.mirnAuth.sendPasswordResetEmail(email)`
  - `adminSoftRemoveUser(uid, email)` — sets `{ active: false, removed: true }` in `users/{uid}` after confirmation

- [ ] **Step 1: Add `#tab-admin` button to `<nav>` (hidden by default, shown only for `super_admin`)**

Add `<button onclick="switchTab('admin')" id="tab-admin" class="hidden tab-btn ..."><span>🛡️</span> <span>لوحة تحكم المسؤول / Admin Panel</span></button>`.

- [ ] **Step 2: Add `#view-admin` section with User Management UI**

Add `<section id="view-admin" class="hidden space-y-6">` containing:
- **Add New User Card:** Name (`#adminNewUserName`), Email (`#adminNewUserEmail`), Password (`#adminNewUserPassword`, min 6 chars), Role select (`#adminNewUserRole` with `manager`, `sales`, `accountant`, `warehouse`, `driver` — never `super_admin`), Submit button calling `adminCreateUser()`.
- **Staff Users Table (`#adminUsersTableBody`):** Name, Email, Role `<select>`, Status badge, and action buttons (Toggle Active/Disable, Reset Password Email, Remove).

- [ ] **Step 3: Implement `adminCreateUser()` with secondary Firebase app + `try/finally` cleanup**

Use `firebase.apps.find(a => a.name === 'SecondaryAdminApp') || firebase.initializeApp(window.mirnFirebaseConfig, 'SecondaryAdminApp')`.
In `try`: create user with email/password, write `users/{cred.user.uid}` with `active: true, removed: false`, log audit `'user_created'`, refresh table.
In `finally`: `await secondaryApp.auth().signOut().catch(() => {})` so `super_admin` session is never touched even on failure.

- [ ] **Step 4: Implement `loadAdminUsers()`, `adminUpdateUserRole()`, `adminToggleUserActive()`, `adminSendPasswordReset()`, and `adminSoftRemoveUser()`**

Ensure every action guards `window.currentUserProfile?.role === 'super_admin'`, updates Firestore, writes an `audit_logs` entry, and shows a toast.

- [ ] **Step 5: Verify user management hooks & secondary app pattern**

Run: `node -e "const fs=require('fs'),h=fs.readFileSync('mirn_system_preview.html','utf8'); console.log('adminView:',h.includes('id=\"view-admin\"'),'secondary:',h.includes('SecondaryAdminApp'),'reset:',h.includes('sendPasswordResetEmail'))"`
Expected: `adminView: true secondary: true reset: true`

- [ ] **Step 6: Commit**

```bash
git add mirn_system_preview.html && git commit -m "feat(admin): add admin panel tab and staff user management via secondary Firebase app"
```

---

### Task 4: Admin Panel Page Controls, Locked Message Editor, & Audit Log Feed

**Files:**
- Modify: `mirn_system_preview.html` (`#view-admin` HTML cards for Page Access Control & Audit Log + JS handlers)

**Interfaces:**
- Consumes: `window.appAccessConfig`, `window.mirnDb`, `writeAuditLog()` from Tasks 1–2
- Produces:
  - `renderAdminPageControls()` — renders Maintenance Mode toggle, global message + phone inputs, and 6-page toggle + role-checkbox + custom-message matrix
  - `saveAdminAccessConfig()` — writes updated `app_config/access_control` to Firestore and logs audit entry
  - `loadAdminAuditLogs()` — queries latest 50 `audit_logs` ordered by `timestamp desc` and renders `#adminAuditLogsBody`

- [ ] **Step 1: Add Page Access & Locked Message Editor card inside `#view-admin`**

Include:
- Global Maintenance Mode checkbox (`#adminMaintenanceToggle`)
- Global Blocked Message input (`#adminGlobalBlockedMsg`)
- Admin Support Phone input (`#adminSupportPhone`)
- Table/grid container `#adminPagesControlList` for the 6 pages (`dashboard`, `pos`, `inventory`, `statements`, `checks`, `fleet`), each with:
  - Active/Inactive toggle switch
  - Role checkboxes (`manager`, `sales`, `accountant`, `warehouse`, `driver`)
  - Optional per-page custom message input
- **Save Access Settings** button calling `saveAdminAccessConfig()`

- [ ] **Step 2: Add Audit Log card inside `#view-admin`**

Include `#adminAuditLogsBody` table + Refresh button calling `loadAdminAuditLogs()` showing Time, Actor Email, Action, Target, and Details.

- [ ] **Step 3: Implement `renderAdminPageControls()`, `saveAdminAccessConfig()`, and `loadAdminAuditLogs()`**

Call `renderAdminPageControls()` and `loadAdminAuditLogs()` whenever `switchTab('admin')` is opened (and re-render controls when `appAccessConfig` updates).

- [ ] **Step 4: Verify all `<script>` tags parse cleanly with `vm.Script` (syntax check)**

Run: `node -e "const fs=require('fs'),vm=require('vm'),h=fs.readFileSync('mirn_system_preview.html','utf8'); const scripts=[...h.matchAll(/<script>([\s\S]*?)<\/script>/g)]; scripts.forEach((m,i)=>new vm.Script(m[1],{filename:'script_'+i+'.js'})); console.log('All',scripts.length,'inline scripts parsed OK')"`
Expected: `All 3 inline scripts parsed OK`

- [ ] **Step 5: Commit**

```bash
git add mirn_system_preview.html && git commit -m "feat(admin): add page toggles, role matrix, custom locked messages, and audit log feed"
```

---

### Task 5: Live Integration Verification & Push to GitHub

**Files:**
- Verify: `mirn_system_preview.html`, `firestore.rules`

- [ ] **Step 1: Pre-flight checklist for Firebase Console (user action)**

Verify and remind the user of the 2 one-time Firebase Console steps:
1. Authentication → Sign-in method → Enable **Email/Password**; Authentication → Users → Add user `dia81994@gmail.com` with your chosen password.
2. Firestore Database → Rules → Paste/deploy updated `firestore.rules`.

- [ ] **Step 2: Run automated static checks on `mirn_system_preview.html` and `firestore.rules`**

Run the inline `vm.Script` parser check + verify `server.js` serves HTTP 200.

- [ ] **Step 3: Push to GitHub `master`**

```bash
git push origin master
```
