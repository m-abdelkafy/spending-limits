import SwiftUI
import SwiftData

struct BudgetEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: [SortDescriptor(\Category.sortOrder), SortDescriptor(\Category.name)])
    private var categories: [Category]

    @Query private var allBudgets: [Budget]

    private let editing: Budget?
    private let month: Date

    @State private var selectedCategory: Category?
    @State private var limitString: String = ""
    @State private var showPicker = false
    @State private var error: String?

    init(editing: Budget? = nil, month: Date) {
        self.editing = editing
        self.month = month
    }

    private var amountDecimal: Decimal? {
        let trimmed = limitString.replacingOccurrences(of: ",", with: ".")
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed)
    }

    private var canSave: Bool {
        selectedCategory != nil && (amountDecimal ?? 0) > 0
    }

    private var availableCategories: [Category] {
        let used = Set(
            allBudgets
                .filter { Budget.normalize(month: $0.month) == Budget.normalize(month: month) && $0.id != editing?.id }
                .compactMap { $0.category?.id }
        )
        return categories.filter { !used.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Button {
                        showPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            if let category = selectedCategory {
                                CategoryTile(category: category, size: 28)
                                Text(category.name)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Choose a category")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .disabled(editing != nil)
                }

                Section("Monthly limit") {
                    HStack {
                        Text(CurrencyFormatter.currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("0", text: $limitString)
                            .keyboardType(.decimalPad)
                            .monospacedDigit()
                    }
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(editing == nil ? "New Limit" : "Edit Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPicker) {
                CategoryPickerView(
                    selection: $selectedCategory,
                    restrictTo: availableCategories
                )
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let editing {
            selectedCategory = editing.category
            limitString = NSDecimalNumber(decimal: editing.limit).stringValue
        }
    }

    private func save() {
        guard let category = selectedCategory else {
            error = "Pick a category."
            return
        }
        guard let amount = amountDecimal, amount > 0 else {
            error = "Enter a limit greater than zero."
            return
        }

        if let editing {
            editing.limit = amount
            editing.category = category
        } else {
            let normalizedMonth = Budget.normalize(month: month)
            if let existing = allBudgets.first(where: {
                Budget.normalize(month: $0.month) == normalizedMonth && $0.category?.id == category.id
            }) {
                existing.limit = amount
            } else {
                context.insert(Budget(month: month, limit: amount, category: category))
            }
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
    BudgetEditorView(month: .now)
        .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self, Budget.self], inMemory: true)
}
