import AppIntents
import SwiftData
import Foundation

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Log a new expense to ExpenseTracker.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Category")
    var category: CategoryEntity

    @Parameter(title: "Account")
    var account: AccountEntity

    @Parameter(title: "Tags", default: nil)
    var tags: [String]?

    @Parameter(title: "Date", default: nil)
    var date: Date?

    @Parameter(title: "Note", default: nil)
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amount) to \(\.$category) from \(\.$account)") {
            \.$tags
            \.$date
            \.$note
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<Double> {
        let context = SharedModelContainer.shared.mainContext

        guard amount > 0 else {
            throw $amount.needsValueError("Enter an amount greater than zero.")
        }

        let categoryID = category.id
        guard let categoryModel = try context.fetch(
            FetchDescriptor<Category>(predicate: #Predicate { $0.id == categoryID })
        ).first else {
            throw $category.needsValueError("Pick a category.")
        }

        let accountID = account.id
        guard let accountModel = try context.fetch(
            FetchDescriptor<Account>(predicate: #Predicate { $0.id == accountID })
        ).first else {
            throw $account.needsValueError("Pick an account.")
        }

        let resolvedTags = try resolveTags(tags ?? [], in: context)
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)

        let expense = Expense(
            amount: Decimal(amount),
            date: date ?? .now,
            note: (trimmedNote?.isEmpty == false) ? trimmedNote : nil,
            category: categoryModel,
            account: accountModel,
            tags: resolvedTags
        )
        context.insert(expense)
        try context.save()

        let dialog = IntentDialog("Added \(CurrencyFormatter.string(from: Decimal(amount))) to \(categoryModel.name).")
        return .result(value: amount, dialog: dialog)
    }

    @MainActor
    private func resolveTags(_ rawNames: [String], in context: ModelContext) throws -> [Tag] {
        var result: [Tag] = []
        var seen = Set<String>()

        for raw in rawNames {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let normalized = Tag.normalize(trimmed)
            if seen.contains(normalized) { continue }
            seen.insert(normalized)

            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.normalizedName == normalized })
            if let existing = try context.fetch(descriptor).first {
                result.append(existing)
            } else {
                let tag = Tag(name: trimmed)
                context.insert(tag)
                result.append(tag)
            }
        }
        return result
    }
}
