# FeedERP — Multi-Branch Animal Feed Distribution ERP

Flutter + Supabase ERP for wholesale animal feed distribution with multiple branches.

---

## Tech Stack

| Layer          | Technology                          |
|----------------|-------------------------------------|
| Frontend       | Flutter (Web, Android, iOS, Desktop)|
| State          | Riverpod                            |
| Navigation     | GoRouter                            |
| Backend        | Supabase (PostgreSQL + Auth + RLS)  |
| Realtime       | Supabase Realtime                   |
| Charts         | fl_chart                            |

---

## Architecture

```
lib/
├── core/
│   ├── constants/      # Table names, app-wide constants
│   ├── errors/         # Failure + Exception classes
│   ├── network/        # Supabase client provider
│   ├── router/         # GoRouter with role-based redirect
│   ├── theme/          # AppTheme (light + dark)
│   └── utils/          # Formatters, UserRole enum
│
└── features/
    ├── auth/           # Login, AppUser entity, AuthNotifier
    ├── branch/         # Branch CRUD, BranchShell nav
    ├── inventory/      # Realtime stock view (event-driven)
    ├── sales/          # Create invoice → confirm → inventory event
    ├── purchases/      # Record purchase → confirm → stock in
    ├── transfers/      # Move stock between branches
    ├── accounting/     # Immutable ledger, P&L summary
    ├── products/       # Product catalogue
    └── admin/          # Multi-branch dashboard, user/branch mgmt
```

Each feature follows **Clean Architecture**:
```
feature/
├── data/
│   ├── datasources/    # Supabase queries
│   ├── models/         # JSON ↔ entity (fromJson/toJson)
│   └── repositories/   # Implements domain repository
├── domain/
│   ├── entities/       # Pure Dart classes (Equatable)
│   ├── repositories/   # Abstract interfaces
│   └── usecases/       # Single-responsibility business logic
└── presentation/
    ├── pages/          # Screens (ConsumerWidget/ConsumerStatefulWidget)
    ├── providers/      # Riverpod providers & notifiers
    └── widgets/        # Reusable UI components
```

---

## Setup

### 1. Supabase Project

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor → New Query**
3. Paste and run `erp_schema.sql` (generated alongside this project)
4. In **Authentication → Users**, create your first admin user
5. In **SQL Editor**, run the seed snippet from the schema to insert the admin into `public.users`

### 2. Flutter

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Run

**Linux/Mac:**
```bash
cp .env.example .env
# Fill in SUPABASE_URL and SUPABASE_ANON_KEY
./run_web.sh
```

**Windows PowerShell:**
```powershell
# Edit run_web.ps1 with your credentials
.\run_web.ps1
```

**Android/iOS:**
```bash
flutter run \
  --dart-define=SUPABASE_URL="https://YOUR_REF.supabase.co" \
  --dart-define=SUPABASE_ANON_KEY="your_key"
```

---

## Key Business Rules (enforced at DB level)

| Rule | Enforcement |
|------|-------------|
| Inventory is event-driven only | `current_inventory` is a SQL VIEW; no stock column |
| `inventory_events` is append-only | Trigger blocks UPDATE + DELETE |
| `transactions` are immutable | Trigger blocks UPDATE + DELETE |
| Events auto-created on sale/purchase confirm | `AFTER UPDATE` SECURITY DEFINER triggers |
| Branch isolation | RLS on every table; `branch_id` mandatory |
| Admin sees all branches | `current_user_role()` helper in all RLS policies |
| Only admin/manager can create products | RLS + role check |

---

## Roles

| Role             | Capabilities |
|------------------|-------------|
| `admin`          | All branches, all data, user management, pricing |
| `branch_manager` | Own branch: sales, purchases, transfers, products |
| `staff`          | Own branch: sales, view inventory/accounting |

---

## Realtime

Supabase Realtime is enabled on:
- `inventory_events` → `inventoryStreamProvider` rebuilds instantly
- `sales` → `salesStreamProvider` rebuilds instantly
- `transactions` → `transactionsStreamProvider` rebuilds instantly

No manual refresh needed anywhere in the UI.

---

## Next Steps

- [ ] PDF invoice generation
- [ ] Push notifications (low stock, pending transfer)
- [ ] Expense recording (non-purchase operational costs)
- [ ] Date range filters on accounting + sales reports
- [ ] Export to Excel/CSV
- [ ] Branch manager transfer approval flow
- [ ] Product price history view
