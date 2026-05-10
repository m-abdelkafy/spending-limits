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
├── Helpers/                # SharedModelContainer, SeedData, formatters
├── Views/
│   ├── Expenses/           # List, row, detail
│   ├── AddExpense/         # The big form
│   └── Settings/           # Categories, Accounts, Tags CRUD
└── Intents/
    ├── AppEntities/        # CategoryEntity, AccountEntity, TagEntity
    ├── AddExpenseIntent.swift
    └── ExpenseShortcutsProvider.swift
```

## Shortcuts

The app registers an `AppShortcutsProvider` so users get the phrase
*"Add expense to ExpenseTracker"* automatically. Categories and accounts use
`AppEntity` pickers; tags are freeform `[String]` so missing tags are
auto-created (case-insensitive matching, preserving the first display casing).
