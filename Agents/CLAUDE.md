# CLAUDE.md

Project: iOS multi-wallet expense and income tracker with screenshot-based receipt import (SwiftUI, MVVM, SwiftData, Vision, Foundation Models). Fully on-device. This is a POC; the final UI will be designed separately.

## Stack and constraints
- Swift (latest stable), SwiftUI, Swift Concurrency (async/await, actors where appropriate). No Combine unless justified.
- Minimum iOS: 26 (required by Foundation Models).
- Persistence: SwiftData.
- No backend, no third-party SDKs, no network calls for extraction.
- Primary locale: Indonesia (IDR, "Rp 1.250.000", dd/MM/yyyy). Keep currency and locale handling extensible.

## POC and UI policy
- Use minimal, system-default UI only. No custom styling.
- Views must be replaceable without touching ViewModels, Services, or Models.
- All visual constants live in a single `DesignTokens` file.
- Business logic is fully implemented and tested; UI polish is not a goal.

## Money and data integrity rules
- Never use `Double` for money. Use integer minor units or `Decimal`.
- Transaction types: income, expense, transfer.
- A transfer is ONE record (source wallet, destination wallet, optional fee). It never counts as income or expense in reports.
- Wallet balance = opening balance + transactions affecting it, never an unverifiable stored value. Balance corrections are explicit adjustment transactions.
- Wallets and categories with history are archived, never hard-deleted.
- Deleting or editing a transaction must keep balances, budgets, and reports consistent. Support undo for delete.
- Month boundaries respect the configurable "month starts on day N" setting.
- Reports and balance math live in pure, testable services, not in ViewModels or Views.

## Architecture rules (strict MVVM)
- **Models**: SwiftData entities and pure value types. No UI logic.
- **ViewModels**: `@Observable`, `@MainActor`, hold UI state only, depend on protocols.
- **Views**: declarative and dumb. No business logic, no direct data access. Under ~150 lines each; extract subviews.
- **Services** (each behind a protocol): `TransactionRepository`, `WalletRepository`, `BudgetRepository`, `ReportingService`, `RecurringTransactionService`, `ReceiptOCRService`, `ReceiptParsingService`, `ExportService`.
- Dependency injection via initializers only. No singletons, no hidden global state.
- Navigation: `NavigationStack` with a typed path; navigation state lives in a router or ViewModel.
- Errors: explicit enums conforming to `LocalizedError`. No silent `try?`.

## Folder structure
```
App/
Core/
  Models/
  Services/
  Utilities/
  DesignTokens/
Features/
  Dashboard/
  Transactions/
  Wallets/
  Reports/
  Budgets/
  ReceiptImport/
  Categories/
  Settings/
Resources/
Tests/
```

## Feature scope
Dashboard, transaction management (income, expense, transfer, search, filters), wallet management (multi-wallet, top-up/adjustment, archive), analytics (income vs expense, category breakdown, trends, daily average), budgets with threshold warnings, category management, recurring transactions, duplicate detection, CSV export/import and backup, settings, optional app lock, onboarding. Stretch: Share Extension / App Intent import, savings goals.

## Receipt extraction pipeline
Do not assume Foundation Models accepts images. Verify against current Apple documentation first. If text-only:
1. `PhotosPicker` for image input.
2. Vision `VNRecognizeTextRequest` (accurate mode, `id-ID` and `en-US`) for OCR.
3. Foundation Models (`LanguageModelSession`) with `@Generable` / `@Guide` to produce a typed struct: amount, currency, merchant/recipient, date, suggested category, suggested wallet, transaction type (purchase / income / transfer / top-up), optional note.
4. Deterministic validation in plain Swift (amount > 0, date not in the future, currency parsing, duplicate check). Never trust model output blindly.
5. Review screen with editable fields and a "needs review" indicator. Nothing is saved without user confirmation.

Always handle:
- `SystemLanguageModel` unavailable (ineligible device, Apple Intelligence off, model not ready) with fallback to manual entry.
- Empty or low-quality OCR output.
- Model output that fails or violates the schema.
- Indonesian formats: QRIS, bank transfer proofs (BCA, Mandiri, BRI, BNI), e-wallets (GoPay, OVO, DANA, ShopeePay), marketplace receipts.

## Code quality
- Small, single-responsibility types. Meaningful names. Doc comments on public protocols and non-obvious logic.
- Localization-ready (String Catalog), accessibility labels, Dynamic Type, dark mode.
- Swift Testing unit tests with mock services for: balances, transfers, adjustments, deletion side effects, budgets, recurring generation, reporting, parsing/validation, duplicate detection, currency/date formatting, month boundaries.
- A SwiftUI preview with mock data for every view; a sample-data generator for previews.

## Workflow
- For any new feature: propose the design first (files, protocols, data flow) and wait for approval before implementing.
- Implement in small, buildable steps. Keep the project compiling after every step.
- After each step, state what was built, what to test, and what is next.
- If a requirement is ambiguous or an API behaves differently than assumed, stop and ask instead of guessing.
- Cite Apple documentation for any framework behavior relied upon.
- Do not add dependencies, change the minimum iOS version, or restructure folders without asking.
