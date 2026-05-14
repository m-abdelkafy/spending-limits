import Foundation
import SwiftData

struct SpendingImportResult {
    var expensesCount = 0
    var incomeCount = 0
    var transferCount = 0
    var skipped = 0
    var createdCategories: [String] = []
    var createdAccounts: [String] = []

    var transactions: Int { expensesCount + incomeCount + transferCount }

    var summary: String {
        var lines = ["\(transactions) transactions imported (\(expensesCount) expense, \(incomeCount) income, \(transferCount) transfer)"]
        if skipped > 0 {
            lines.append("\(skipped) row(s) skipped")
        }
        if !createdAccounts.isEmpty {
            lines.append("New accounts: \(createdAccounts.joined(separator: ", "))")
        }
        if !createdCategories.isEmpty {
            lines.append("New categories: \(createdCategories.joined(separator: ", "))")
        }
        return lines.joined(separator: "\n")
    }
}

struct SpendingCSVImporter {

    private static let categoryPalette = [
        "#FF6B6B", "#4F8EF7", "#FFB400", "#9B59B6",
        "#1ABC9C", "#FF7849", "#34C759", "#5856D6",
    ]

    func importData(from url: URL, into context: ModelContext) throws -> SpendingImportResult {
        let rows = try CSVParser.parse(url: url)
        guard rows.count > 1 else { return SpendingImportResult() }

        let header = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let columns = ColumnIndex(header: header)

        var result = SpendingImportResult()
        var categoryCache: [String: Category] = [:]
        var accountCache: [String: Account] = [:]
        var tagCache: [String: Tag] = [:]
        var nextCategorySort = try nextCategorySortOrder(context: context)
        var nextAccountSort = try nextAccountSortOrder(context: context)

        // Track transfer pairs so we only insert one Expense per pair.
        var seenTransferKeys = Set<String>()

        for rowIdx in 1..<rows.count {
            let row = rows[rowIdx]
            guard !row.allSatisfy({ $0.isEmpty }) else { continue }

            let pending = columns.value(in: row, for: .pending).lowercased()
            if pending == "true" || pending == "1" || pending == "yes" {
                result.skipped += 1
                continue
            }

            let rawAmount = columns.value(in: row, for: .amount)
            guard let signed = Decimal(string: rawAmount.replacingOccurrences(of: ",", with: ".")) else {
                result.skipped += 1
                continue
            }
            guard let date = parseDate(columns.value(in: row, for: .date)) else {
                result.skipped += 1
                continue
            }

            let amount = abs(signed)
            let source = trimmed(columns.value(in: row, for: .sourceAccount))
            let target = trimmed(columns.value(in: row, for: .targetAccount))
            let categoryName = trimmed(columns.value(in: row, for: .category))
            let payee = trimmed(columns.value(in: row, for: .payee))
            let notes = trimmed(columns.value(in: row, for: .notes))
            let tagsField = columns.value(in: row, for: .tags)

            let kind: TransactionKind
            if !source.isEmpty && !target.isEmpty {
                kind = .transfer
            } else if signed > 0 {
                kind = .income
            } else {
                kind = .expense
            }

            // For transfers, only keep the negative side of the pair to avoid duplicates.
            if kind == .transfer {
                if signed > 0 { continue }
                let key = transferKey(date: date, amount: amount, from: source, to: target)
                if !seenTransferKeys.insert(key).inserted { continue }
            }

            // Resolve / create accounts
            let account = try resolveAccount(
                name: source,
                cache: &accountCache,
                nextSort: &nextAccountSort,
                createdNames: &result.createdAccounts,
                context: context
            )
            let toAccount: Account? = kind == .transfer
                ? try resolveAccount(
                    name: target,
                    cache: &accountCache,
                    nextSort: &nextAccountSort,
                    createdNames: &result.createdAccounts,
                    context: context
                )
                : nil

            // Resolve / create category (none for transfers)
            let category: Category?
            if kind == .transfer || categoryName.isEmpty {
                category = nil
            } else {
                category = try resolveCategory(
                    name: categoryName,
                    cache: &categoryCache,
                    nextSort: &nextCategorySort,
                    createdNames: &result.createdCategories,
                    context: context
                )
            }

            // Tags (pipe-separated). Also try comma-separated if no pipes are present.
            let separators: [Character] = tagsField.contains("|") ? ["|"] : [","]
            let tagNames = tagsField
                .split(whereSeparator: { separators.contains($0) })
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let tags = try tagNames.map { name -> Tag in
                try resolveTag(name: name, cache: &tagCache, context: context)
            }

            // Note: prefer the Notes column; fall back to Payee.
            let resolvedNote: String? = {
                if !notes.isEmpty { return notes }
                if !payee.isEmpty { return payee }
                return nil
            }()

            let expense = Expense(
                amount: amount,
                date: date,
                note: resolvedNote,
                kind: kind,
                category: category,
                account: account,
                toAccount: toAccount,
                tags: tags
            )
            context.insert(expense)

            switch kind {
            case .expense: result.expensesCount += 1
            case .income: result.incomeCount += 1
            case .transfer: result.transferCount += 1
            }
        }

        try context.save()
        return result
    }

    // MARK: - Helpers

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func transferKey(date: Date, amount: Decimal, from: String, to: String) -> String {
        "\(date.timeIntervalSince1970)|\(amount)|\(from)|\(to)"
    }

    private func resolveAccount(
        name: String,
        cache: inout [String: Account],
        nextSort: inout Int,
        createdNames: inout [String],
        context: ModelContext
    ) throws -> Account? {
        let trimmedName = trimmed(name)
        guard !trimmedName.isEmpty else { return nil }
        if let cached = cache[trimmedName] { return cached }
        let descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.name == trimmedName })
        if let existing = try context.fetch(descriptor).first {
            cache[trimmedName] = existing
            return existing
        }
        let account = Account(name: trimmedName, type: .other, sortOrder: nextSort)
        context.insert(account)
        cache[trimmedName] = account
        createdNames.append(trimmedName)
        nextSort += 1
        return account
    }

    private func resolveCategory(
        name: String,
        cache: inout [String: Category],
        nextSort: inout Int,
        createdNames: inout [String],
        context: ModelContext
    ) throws -> Category? {
        let trimmedName = trimmed(name)
        guard !trimmedName.isEmpty else { return nil }
        if let cached = cache[trimmedName] { return cached }
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.name == trimmedName })
        if let existing = try context.fetch(descriptor).first {
            cache[trimmedName] = existing
            return existing
        }
        let color = Self.categoryPalette[nextSort % Self.categoryPalette.count]
        let category = Category(name: trimmedName, icon: "tag", colorHex: color, sortOrder: nextSort)
        context.insert(category)
        cache[trimmedName] = category
        createdNames.append(trimmedName)
        nextSort += 1
        return category
    }

    private func resolveTag(name: String, cache: inout [String: Tag], context: ModelContext) throws -> Tag {
        let normalized = Tag.normalize(name)
        if let cached = cache[normalized] { return cached }
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.normalizedName == normalized })
        if let existing = try context.fetch(descriptor).first {
            cache[normalized] = existing
            return existing
        }
        let tag = Tag(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(tag)
        cache[normalized] = tag
        return tag
    }

    private func nextAccountSortOrder(context: ModelContext) throws -> Int {
        let all = try context.fetch(FetchDescriptor<Account>())
        return (all.map(\.sortOrder).max() ?? -1) + 1
    }

    private func nextCategorySortOrder(context: ModelContext) throws -> Int {
        let all = try context.fetch(FetchDescriptor<Category>())
        return (all.map(\.sortOrder).max() ?? -1) + 1
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let fallbackFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return f
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func parseDate(_ raw: String) -> Date? {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if let d = Self.isoFormatter.date(from: s) { return d }
        if let d = Self.fallbackFormatter.date(from: s) { return d }
        if let d = Self.dateOnlyFormatter.date(from: s) { return d }
        return nil
    }
}

// MARK: - Column lookup

private struct ColumnIndex {
    enum Column: String {
        case date = "Date"
        case amount = "Amount"
        case sourceAccount = "Source Account"
        case targetAccount = "Target Account"
        case category = "Category"
        case payee = "Payee"
        case tags = "Tags"
        case notes = "Notes"
        case pending = "Pending"
    }

    private let indices: [Column: Int]

    init(header: [String]) {
        var map: [Column: Int] = [:]
        for (i, raw) in header.enumerated() {
            let key = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            for column in [Column.date, .amount, .sourceAccount, .targetAccount,
                           .category, .payee, .tags, .notes, .pending] {
                if column.rawValue.lowercased() == key {
                    map[column] = i
                }
            }
        }
        self.indices = map
    }

    func value(in row: [String], for column: Column) -> String {
        guard let i = indices[column], i < row.count else { return "" }
        return row[i]
    }
}
