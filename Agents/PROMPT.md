You are a senior iOS engineer. Help me build a proof-of-concept (POC) personal finance iOS app called [APP NAME] using SwiftUI and a clean, strict MVVM architecture.

## Product goal
A multi-wallet expense and income tracker whose differentiator is importing transactions from screenshots of receipts, payment confirmations, and bank/e-wallet transfer proofs. The user picks a screenshot, the app extracts the details, shows them for review, and saves them as a transaction.

## POC scope and design approach
- This is a POC. I will design the final UI myself later.
- Build functional, minimal, system-default UI only (standard List, Form, NavigationStack, Swift Charts). No custom styling.
- Keep UI swappable: Views must be thin and render only state exposed by ViewModels, so I can replace every View without touching ViewModels, Services, or Models.
- Put any visual constants (colors, spacing, fonts) in one `DesignTokens` file so they can be replaced later.
- All business logic must be fully implemented and unit-tested. Prioritize correctness of money logic over UI polish.

## Target and constraints
- Swift (latest stable), SwiftUI, Swift Concurrency. No Combine unless justified.
- Minimum iOS: [iOS 26, required by Foundation Models].
- Persistence: SwiftData. Fully on-device. No backend, no third-party SDKs.
- Primary locale: Indonesia (IDR, "Rp 1.250.000", dd/MM/yyyy, Indonesian and English text). Keep currency and locale handling extensible.

## Money and data integrity rules (decide these first, then follow strictly)
- Store amounts as integer minor units or `Decimal`. Never `Double`.
- Transaction types: income, expense, transfer.
- A transfer is ONE record with a source wallet and a destination wallet (plus optional fee), not two separate transactions. It must not count as income or expense in reports.
- Wallet balance = opening balance + sum of transactions affecting it. Compute it from transactions (or keep a cached value that is provably consistent) so it can never drift. Balance adjustment ("top up / correct balance") is recorded as an explicit adjustment transaction, not a silent overwrite.
- Wallets with history can only be archived, never hard-deleted. Categories in use can only be archived or reassigned.
- Deleting a transaction must update all derived values (balances, budgets, reports) correctly. Offer undo.
- Monthly boundaries and "first day of week" use the user's calendar and a configurable "month starts on day N" setting (many Indonesian users are paid on the 25th-1st).

## Features

### 1. Dashboard / Home
- Total balance across all non-archived wallets (with option to exclude a wallet from the total).
- This month's total income and expense, and net cash flow.
- Expense chart for the current period.
- Recent transactions.
- Budget status summary (if budgets exist).
- Quick add transaction (income / expense / transfer / import from screenshot).

### 2. Transaction management
- Add income, add expense, transfer between wallets.
- Edit and delete transactions.
- Choose category, date and time, wallet; optional note and tags.
- History with search (note, merchant, category, amount) and filters (type, wallet, category, date range, tags).
- Group by day with daily totals.
- Optional: attach the original receipt image to a transaction (stored locally).

### 3. Wallet management
- Multiple wallets with a type (Cash, Bank, E-Wallet, Other), name, icon placeholder, currency.
- Balance per wallet, opening balance.
- Top up / balance adjustment.
- Transfer between wallets.
- Transaction history per wallet.
- Edit and archive wallet.

### 4. Analytics / reports
- Income vs expense chart.
- Expense breakdown by category.
- Weekly and monthly trends.
- Top spending categories.
- Period filter (week, month, custom range).
- Average daily spending.
- Transfers excluded from income/expense totals.

### 5. Additional features (not in my original list, please include)
- **Budgets**: monthly budget per category and an optional overall budget; progress, remaining amount, and over-budget state. Notification or in-app warning at a configurable threshold (e.g. 80% and 100%).
- **Category management**: default set plus custom categories (add, edit, archive, reorder), separate sets for income and expense.
- **Recurring transactions**: schedules (daily, weekly, monthly, custom) for bills, salary, subscriptions; auto-generate due transactions on app launch, with an option to confirm before posting.
- **Duplicate detection** (important for screenshot import): warn when an imported transaction closely matches an existing one (same amount, similar date, same merchant or wallet).
- **Wallet suggestion on import**: infer the likely wallet from the receipt (e.g. GoPay receipt suggests the GoPay wallet) and let the user override.
- **Income and transfer detection on import**: recognize received transfers (income) and transfers between the user's own wallets, not only purchases.
- **Batch import**: select multiple screenshots and review them one by one in a queue.
- **Export and backup**: export transactions to CSV; import from CSV; local backup and restore.
- **Settings**: default currency, month start day, first day of week, default wallet, notification preferences, appearance (system/light/dark).
- **Security**: optional Face ID / passcode lock for the app.
- **Onboarding**: first-run flow to create the first wallet and choose starting categories.
- **Share Extension / App Intent** (stretch): import a screenshot straight from the Photos share sheet or via Shortcuts.
- **Savings goals** (stretch, lowest priority).

## Receipt extraction pipeline
Do NOT assume Foundation Models can take an image as input. Before designing, verify against current Apple documentation what the framework supports. If text-only:
1. Image input: PhotosPicker.
2. OCR: Vision `VNRecognizeTextRequest` (languages "id-ID" and "en-US", accurate mode).
3. Structuring: Foundation Models (`LanguageModelSession`) with `@Generable` / `@Guide` to produce a typed struct: amount, currency, merchant/recipient, date, suggested category, suggested wallet, transaction type (purchase / income / transfer / top-up), optional note.
4. Validation layer: deterministic Swift checks (amount > 0, date not in the future, currency parsing, duplicate check). Never trust model output blindly.
5. Review screen: editable fields with a "needs review" indicator for uncertain fields. Nothing is saved without user confirmation.

Handle explicitly:
- `SystemLanguageModel` unavailable (ineligible device, Apple Intelligence off, model not ready) with graceful fallback to manual entry.
- Empty or low-quality OCR text.
- Model output that fails or violates the schema.
- Indonesian formats: QRIS, bank transfer proofs (BCA, Mandiri, BRI, BNI), e-wallets (GoPay, OVO, DANA, ShopeePay), marketplace receipts.

## Architecture requirements (strict)
- MVVM:
  - Models: SwiftData entities and pure value types. No UI logic.
  - ViewModels: `@Observable`, `@MainActor`, UI state only, depend on protocols.
  - Views: dumb and declarative. No business logic, no direct data access.
  - Services behind protocols: `ExpenseRepository` / `TransactionRepository`, `WalletRepository`, `BudgetRepository`, `ReportingService` (aggregations), `RecurringTransactionService`, `ReceiptOCRService`, `ReceiptParsingService`, `ExportService`.
- Dependency injection via initializers. No singletons or hidden global state.
- Feature-based folders (Features/Dashboard, Transactions, Wallets, Reports, Budgets, ReceiptImport, Settings; Core/Models, Services, Utilities, DesignTokens).
- Explicit error types (`LocalizedError`), no silent `try?`.
- `NavigationStack` with typed paths; navigation state in a router or ViewModel.
- Reporting and balance calculations live in services (pure, testable), not in ViewModels or Views.

## Code quality
- Small single-responsibility types. No view over ~150 lines.
- Doc comments on public protocols and non-obvious logic.
- Localization-ready (String Catalog), accessibility labels, Dynamic Type, dark mode.
- Unit tests (Swift Testing) with mocks for: balance calculation, transfers, adjustments, deletion side effects, budgets, recurring generation, reporting aggregations, parsing/validation, duplicate detection, currency/date formatting, month-boundary logic.
- Previews for every view with mock data.
- Seed/sample data generator for previews and manual testing.

## How to work
1. First, DO NOT write code. Reply with: (a) verified Foundation Models capabilities and limits relevant to this app, (b) folder structure, (c) data model with relationships and the money-integrity decisions above, (d) service protocol definitions, (e) feature priority order for the POC (what is core vs stretch), (f) open questions and risks.
2. Wait for my approval, then implement in small, buildable steps in this order: Models and repositories (wallets, categories, transactions, transfers, balances) -> transaction CRUD -> reporting service and dashboard data -> budgets -> recurring -> OCR service -> parsing service -> import flow (with duplicate and wallet detection) -> export/backup -> settings and security.
3. After each step: state what was built, what to test, and what is next. Keep every step compiling.
4. If a requirement is ambiguous or an API behaves differently than assumed, stop and ask. Cite Apple documentation for any framework behavior you rely on.
