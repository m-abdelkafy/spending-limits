import Foundation
import SwiftData

struct DataExporter {

    func export(
        accounts: [Account],
        categories: [Category],
        tags: [Tag],
        expenses: [Expense]
    ) throws -> [URL] {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ExpenseTrackerExport_\(datestamp())", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let files: [(String, String)] = [
            ("ExpenseTracker_accounts_\(datestamp()).csv", accountsCSV(accounts)),
            ("ExpenseTracker_categories_\(datestamp()).csv", categoriesCSV(categories)),
            ("ExpenseTracker_tags_\(datestamp()).csv", tagsCSV(tags)),
            ("ExpenseTracker_expenses_\(datestamp()).csv", expensesCSV(expenses)),
        ]

        return try files.map { name, content in
            let url = dir.appendingPathComponent(name)
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        }
    }

    // MARK: - CSV builders

    private func expensesCSV(_ expenses: [Expense]) -> String {
        var rows = ["id,amount,date,note,createdAt,category,account,tags"]
        for e in expenses {
            rows.append([
                e.id.uuidString,
                "\(e.amount)",
                iso8601.string(from: e.date),
                e.note ?? "",
                iso8601.string(from: e.createdAt),
                e.category?.name ?? "",
                e.account?.name ?? "",
                e.tags.map(\.name).joined(separator: "|"),
            ].map(csvEscape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private func categoriesCSV(_ categories: [Category]) -> String {
        var rows = ["id,name,icon,colorHex,sortOrder"]
        for c in categories {
            rows.append([
                c.id.uuidString, c.name, c.icon, c.colorHex, "\(c.sortOrder)",
            ].map(csvEscape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private func accountsCSV(_ accounts: [Account]) -> String {
        var rows = ["id,name,type,sortOrder"]
        for a in accounts {
            rows.append([
                a.id.uuidString, a.name, a.typeRaw, "\(a.sortOrder)",
            ].map(csvEscape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private func tagsCSV(_ tags: [Tag]) -> String {
        var rows = ["id,name"]
        for t in tags {
            rows.append([t.id.uuidString, t.name].map(csvEscape).joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - Helpers

    private func csvEscape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private func datestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private var iso8601: ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }
}
