import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse), SortDescriptor(\Expense.createdAt, order: .reverse)])
    private var expenses: [Expense]

    @State private var showAdd = false

    private var grouped: [(day: Date, items: [Expense])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: expenses) { cal.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { key in
            (day: key, items: dict[key] ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if expenses.isEmpty {
                        EmptyExpensesView()
                    } else {
                        List {
                            ForEach(grouped, id: \.day) { group in
                                Section {
                                    ForEach(group.items) { expense in
                                        NavigationLink {
                                            ExpenseDetailView(expense: expense)
                                        } label: {
                                            ExpenseRowView(expense: expense)
                                        }
                                    }
                                    .onDelete { offsets in
                                        delete(at: offsets, in: group.items)
                                    }
                                } header: {
                                    DayHeaderView(day: group.day, total: total(of: group.items))
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }

                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.accentColor))
                        .shadow(radius: 6, y: 3)
                }
                .padding(20)
                .accessibilityLabel("Add expense")
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PrivacyToggleButton()
                }
            }
            .sheet(isPresented: $showAdd) {
                AddExpenseView(onSaved: { showAdd = false })
            }
        }
    }

    private func total(of items: [Expense]) -> Decimal {
        items.filter { $0.kind == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private func delete(at offsets: IndexSet, in items: [Expense]) {
        for index in offsets {
            context.delete(items[index])
        }
        try? context.save()
    }
}

private struct DayHeaderView: View {
    let day: Date
    let total: Decimal

    var body: some View {
        HStack {
            Text(day, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(CurrencyFormatter.string(from: total))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .privacyBlur()
        }
        .textCase(nil)
    }
}

private struct EmptyExpensesView: View {
    var body: some View {
        ContentUnavailableView(
            "No expenses yet",
            systemImage: "tray",
            description: Text("Tap the + button or use the “Add expense to ExpenseTracker” shortcut to get started.")
        )
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self], inMemory: true)
}
