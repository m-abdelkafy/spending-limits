import SwiftUI
import SwiftData

struct ExpenseDetailView: View {
    @Bindable var expense: Expense
    @State private var isEditing = false

    var body: some View {
        Form {
            Section("Amount") {
                Text(CurrencyFormatter.string(from: expense.amount))
                    .font(.largeTitle.weight(.semibold))
                    .monospacedDigit()
            }

            Section("Details") {
                LabeledContent("Date") {
                    Text(expense.date, format: .dateTime.month().day().year().hour().minute())
                }
                LabeledContent("Category") {
                    Text(expense.category?.name ?? "—")
                }
                LabeledContent("Account") {
                    Text(expense.account?.name ?? "—")
                }
                if let note = expense.note, !note.isEmpty {
                    LabeledContent("Note") {
                        Text(note)
                    }
                }
            }

            if !expense.tags.isEmpty {
                Section("Tags") {
                    Text(expense.tags.map { "#\($0.name)" }.joined(separator: "  "))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            AddExpenseView(editing: expense, onSaved: { isEditing = false })
        }
    }
}
