import SwiftUI
import SwiftData

struct ExpenseDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var expense: Expense
    @State private var isEditing = false
    @State private var isConfirmingDelete = false

    var body: some View {
        Form {
            Section("Amount") {
                Text(CurrencyFormatter.string(from: expense.amount))
                    .font(.largeTitle.weight(.semibold))
                    .monospacedDigit()
            }

            Section("Details") {
                LabeledContent("Type") {
                    Text(expense.kind.displayName)
                }
                LabeledContent("Date") {
                    Text(expense.date, format: .dateTime.month().day().year().hour().minute())
                }
                if expense.kind != .transfer {
                    LabeledContent("Category") {
                        Text(expense.category?.name ?? "—")
                    }
                }
                LabeledContent(expense.kind == .transfer ? "From" : "Account") {
                    Text(expense.account?.name ?? "—")
                }
                if expense.kind == .transfer {
                    LabeledContent("To") {
                        Text(expense.toAccount?.name ?? "—")
                    }
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

            Section {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(expense.kind.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { isEditing = true }
        }
        .sheet(isPresented: $isEditing) {
            AddExpenseView(editing: expense, onSaved: { isEditing = false })
        }
        .confirmationDialog("Delete this transaction?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(expense)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
