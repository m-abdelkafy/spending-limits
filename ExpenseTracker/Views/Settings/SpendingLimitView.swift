import SwiftUI
import SwiftData

struct SpendingLimitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var allBudgets: [Budget]
    @Query private var limits: [SpendingLimit]

    private let month = Budget.normalize(month: .now)

    @State private var amountString: String = ""
    @State private var error: String?

    private var amountDecimal: Decimal? {
        let trimmed = amountString.replacingOccurrences(of: ",", with: ".")
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed)
    }

    private var budgetTotal: Decimal {
        allBudgets
            .filter { Budget.normalize(month: $0.month) == month }
            .reduce(Decimal(0)) { $0 + $1.limit }
    }

    private var existingLimit: SpendingLimit? {
        limits.first { Budget.normalize(month: $0.month) == month }
    }

    private var canSave: Bool {
        (amountDecimal ?? 0) > 0
    }

    var body: some View {
        Form {
            Section("Budgets total") {
                HStack {
                    Text(monthTitle)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(CurrencyFormatter.string(from: budgetTotal))
                        .monospacedDigit()
                        .privacyBlur()
                }
            }

            Section("Monthly spending limit") {
                HStack {
                    Text(CurrencyFormatter.currencySymbol)
                        .foregroundStyle(.secondary)
                    TextField("0", text: $amountString)
                        .keyboardType(.decimalPad)
                        .monospacedDigit()
                }
            } footer: {
                Text("Must be greater than the total of your category budgets for this month.")
            }

            if let error {
                Section {
                    Text(error).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Spending limit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!canSave)
                    .fontWeight(.semibold)
            }
        }
        .onAppear(perform: load)
    }

    private var monthTitle: String {
        Date.now.formatted(.dateTime.month(.wide))
    }

    private func load() {
        if let existingLimit {
            amountString = NSDecimalNumber(decimal: existingLimit.amount).stringValue
        }
    }

    private func save() {
        guard let amount = amountDecimal, amount > 0 else {
            error = "Enter a limit greater than zero."
            return
        }
        guard amount > budgetTotal else {
            error = "Limit must be greater than your budgets total (\(CurrencyFormatter.string(from: budgetTotal)))."
            return
        }

        if let existingLimit {
            existingLimit.amount = amount
        } else {
            context.insert(SpendingLimit(month: month, amount: amount))
        }

        do {
            try context.save()
            dismiss()
        } catch {
            self.error = "Could not save: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        SpendingLimitView()
    }
    .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self, Budget.self, SpendingLimit.self], inMemory: true)
}
