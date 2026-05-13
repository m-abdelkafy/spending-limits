# ExpenseTracker

Lean iOS expense tracker built in Swift/SwiftUI with SwiftData persistence and iOS Shortcuts integration via App Intents.

## Requirements

- Xcode 16+
- iOS 18.0+ (deployment target)
- Swift 5.10+

## Getting started

Open the project in Xcode and run on a simulator or device:

```bash
open ExpenseTracker.xcodeproj
```

Two project descriptions are kept in sync:

- `ExpenseTracker.xcodeproj/project.pbxproj` — the working Xcode project (committed).
- `project.yml` — XcodeGen spec used to regenerate the project from sources.

If you add or remove Swift files and don't want to manage the pbxproj by hand, regenerate it:

```bash
python3 scripts/generate_pbxproj.py
```

(Or use [XcodeGen](https://github.com/yonaskolb/XcodeGen) with `project.yml`.)

## Project layout

```
ExpenseTracker/
├── App/                    # @main + ModelContainer setup
├── Models/                 # SwiftData @Model: Expense, Category, Account, Tag
├── Helpers/                # SharedModelContainer, SeedData, DataExporter, DataImporter, formatters
├── Views/
│   ├── Expenses/           # List, row, detail
│   ├── AddExpense/         # The big form
│   └── Settings/           # Categories, Accounts, Tags CRUD, Import/Export
└── Intents/
    ├── AppEntities/        # CategoryEntity, AccountEntity, TagEntity
    ├── AddExpenseIntent.swift
    └── ExpenseShortcutsProvider.swift
```

## Import / Export

**Settings → Import / Export** lets you back up and restore all app data as CSV files.

**Export** produces 4 files shared via the system share sheet:

| File | Contents |
|---|---|
| `ExpenseTracker_expenses_<date>.csv` | id, amount, date, note, createdAt, category, account, tags |
| `ExpenseTracker_categories_<date>.csv` | id, name, icon, colorHex, sortOrder |
| `ExpenseTracker_accounts_<date>.csv` | id, name, type, sortOrder |
| `ExpenseTracker_tags_<date>.csv` | id, name |

**Import** accepts all 4 files at once (multi-file picker). Records are upserted by UUID — existing records are updated, new ones are inserted. Import order: accounts → categories → tags → expenses.

## Shortcuts

The app registers an `AppShortcutsProvider` so users get the phrase
*"Add expense to ExpenseTracker"* automatically. Categories and accounts use
`AppEntity` pickers; tags are freeform `[String]` so missing tags are
auto-created (case-insensitive matching, preserving the first display casing).

## CI / TestFlight

The repository includes a GitHub Actions workflow (`.github/workflows/testflight.yml`) that builds the app and uploads it to TestFlight. It is triggered **manually** via `workflow_dispatch` (Actions → TestFlight → Run workflow).

### Required GitHub Actions secrets

| Secret | Description |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | Base64-encoded `.p12` distribution certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password for the `.p12` |
| `KEYCHAIN_PASSWORD` | Any string — used for the temporary CI keychain |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64-encoded App Store `.mobileprovision` |
| `APPLE_PROVISIONING_PROFILE_NAME` | Profile name as shown in Xcode / developer portal |
| `APPLE_TEAM_ID` | 10-character Apple Developer Team ID |
| `ASC_KEY_ID` | App Store Connect API Key ID |
| `ASC_ISSUER_ID` | App Store Connect API Issuer ID |
| `ASC_PRIVATE_KEY` | Base64-encoded contents of the `.p8` key file |

Build numbers increment automatically using the GitHub Actions run number (`GITHUB_RUN_NUMBER`).
