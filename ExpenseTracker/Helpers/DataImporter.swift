import Foundation
import SwiftData

struct ImportResult {
    var accountsCount = 0
    var categoriesCount = 0
    var tagsCount = 0
    var expensesCount = 0

    var summary: String {
        "\(expensesCount) expenses, \(categoriesCount) categories, \(accountsCount) accounts, \(tagsCount) tags"
    }
}

struct DataImporter {

    func importData(from urls: [URL], into context: ModelContext) throws -> ImportResult {
        var result = ImportResult()

        // Detect and group files by type
        var accountsURL: URL?
        var categoriesURL: URL?
        var tagsURL: URL?
        var expensesURL: URL?

        for url in urls {
            let name = url.lastPathComponent.lowercased()
            if name.contains("_accounts_") { accountsURL = url }
            else if name.contains("_categories_") { categoriesURL = url }
            else if name.contains("_tags_") { tagsURL = url }
            else if name.contains("_expenses_") { expensesURL = url }
        }

        // Import in dependency order
        if let url = accountsURL {
            result.accountsCount = try importAccounts(from: url, into: context)
        }
        if let url = categoriesURL {
            result.categoriesCount = try importCategories(from: url, into: context)
        }
        if let url = tagsURL {
            result.tagsCount = try importTags(from: url, into: context)
        }
        if let url = expensesURL {
            result.expensesCount = try importExpenses(from: url, into: context)
        }

        try context.save()
        return result
    }

    // MARK: - Entity importers

    private func importAccounts(from url: URL, into context: ModelContext) throws -> Int {
        let rows = try parseCSV(url: url).dropFirst() // skip header
        var count = 0
        for row in rows {
            guard row.count >= 4, let id = UUID(uuidString: row[0]) else { continue }
            let existing = try fetchAccount(id: id, context: context)
            if let account = existing {
                account.name = row[1]
                account.typeRaw = row[2]
                account.sortOrder = Int(row[3]) ?? account.sortOrder
            } else {
                let account = Account(
                    id: id,
                    name: row[1],
                    type: AccountType(rawValue: row[2]) ?? .other,
                    sortOrder: Int(row[3]) ?? 0
                )
                context.insert(account)
            }
            count += 1
        }
        return count
    }

    private func importCategories(from url: URL, into context: ModelContext) throws -> Int {
        let rows = try parseCSV(url: url).dropFirst()
        var count = 0
        for row in rows {
            guard row.count >= 5, let id = UUID(uuidString: row[0]) else { continue }
            let existing = try fetchCategory(id: id, context: context)
            if let category = existing {
                category.name = row[1]
                category.icon = row[2]
                category.colorHex = row[3]
                category.sortOrder = Int(row[4]) ?? category.sortOrder
            } else {
                let category = Category(
                    id: id,
                    name: row[1],
                    icon: row[2],
                    colorHex: row[3],
                    sortOrder: Int(row[4]) ?? 0
                )
                context.insert(category)
            }
            count += 1
        }
        return count
    }

    private func importTags(from url: URL, into context: ModelContext) throws -> Int {
        let rows = try parseCSV(url: url).dropFirst()
        var count = 0
        for row in rows {
            guard row.count >= 2, let id = UUID(uuidString: row[0]) else { continue }
            let name = row[1]
            let normalized = Tag.normalize(name)
            // Match by normalized name first to avoid duplicate unique-constraint violation
            let existing = try fetchTag(normalizedName: normalized, context: context)
            if existing == nil {
                let tag = Tag(id: id, name: name)
                context.insert(tag)
                count += 1
            }
        }
        return count
    }

    private func importExpenses(from url: URL, into context: ModelContext) throws -> Int {
        let rows = try parseCSV(url: url).dropFirst()
        var count = 0
        for row in rows {
            guard row.count >= 8, let id = UUID(uuidString: row[0]) else { continue }
            guard let amount = Decimal(string: row[1]),
                  let date = iso8601.date(from: row[2]) else { continue }
            let note = row[3].isEmpty ? nil : row[3]
            let createdAt = iso8601.date(from: row[4]) ?? date
            let categoryName = row[5]
            let accountName = row[6]
            let tagNames = row[7].split(separator: "|").map(String.init).filter { !$0.isEmpty }

            let category = categoryName.isEmpty ? nil : try fetchCategory(name: categoryName, context: context)
            let account = accountName.isEmpty ? nil : try fetchAccount(name: accountName, context: context)
            let tags = try tagNames.compactMap { try fetchTag(normalizedName: Tag.normalize($0), context: context) }

            let existing = try fetchExpense(id: id, context: context)
            if let expense = existing {
                expense.amount = amount
                expense.date = date
                expense.note = note
                expense.createdAt = createdAt
                expense.category = category
                expense.account = account
                expense.tags = tags
            } else {
                let expense = Expense(
                    id: id,
                    amount: amount,
                    date: date,
                    note: note,
                    createdAt: createdAt,
                    category: category,
                    account: account,
                    tags: tags
                )
                context.insert(expense)
            }
            count += 1
        }
        return count
    }

    // MARK: - Fetch helpers

    private func fetchAccount(id: UUID, context: ModelContext) throws -> Account? {
        let descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    private func fetchAccount(name: String, context: ModelContext) throws -> Account? {
        let descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.name == name })
        return try context.fetch(descriptor).first
    }

    private func fetchCategory(id: UUID, context: ModelContext) throws -> Category? {
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    private func fetchCategory(name: String, context: ModelContext) throws -> Category? {
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.name == name })
        return try context.fetch(descriptor).first
    }

    private func fetchTag(normalizedName: String, context: ModelContext) throws -> Tag? {
        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.normalizedName == normalizedName })
        return try context.fetch(descriptor).first
    }

    private func fetchExpense(id: UUID, context: ModelContext) throws -> Expense? {
        let descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    // MARK: - CSV parser

    private func parseCSV(url: URL) throws -> [[String]] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return text.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { parseCSVRow($0) }
    }

    private func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        var i = row.startIndex

        while i < row.endIndex {
            let ch = row[i]
            if inQuotes {
                if ch == "\"" {
                    let next = row.index(after: i)
                    if next < row.endIndex && row[next] == "\"" {
                        current.append("\"")
                        i = row.index(after: next)
                        continue
                    } else {
                        inQuotes = false
                    }
                } else {
                    current.append(ch)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                } else if ch == "," {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(ch)
                }
            }
            i = row.index(after: i)
        }
        fields.append(current)
        return fields
    }

    private var iso8601: ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }
}
