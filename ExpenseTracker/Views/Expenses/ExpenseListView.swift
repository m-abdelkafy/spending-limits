import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse), SortDescriptor(\Expense.createdAt, order: .reverse)])
    private var expenses: [Expense]

    @State private var showAdd = false
    @State private var selectedMonth: Date = Budget.normalize(month: .now)

    private var monthInterval: DateInterval { MonthSummary.interval(of: selectedMonth) }

    private var filteredExpenses: [Expense] {
        expenses.filter { monthInterval.contains($0.date) }
    }

    private var grouped: [(day: Date, items: [Expense])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: filteredExpenses) { cal.startOfDay(for: $0.date) }
        return dict.keys.sorted(by: >).map { key in
            (day: key, items: dict[key] ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if filteredExpenses.isEmpty {
                        EmptyExpensesView(isCurrentMonth: isCurrentMonth)
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
                ToolbarItem(placement: .principal) {
                    MonthPickerView(month: $selectedMonth)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    PrivacyToggleButton()
                }
            }
            .sheet(isPresented: $showAdd) {
                AddExpenseView(onSaved: { showAdd = false })
            }
        }
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: .now, toGranularity: .month)
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
            Text(dayLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text(CurrencyFormatter.string(from: total))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .privacyBlur()
        }
        .textCase(nil)
    }

    private var dayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

private struct EmptyExpensesView: View {
    let isCurrentMonth: Bool

    var body: some View {
        if isCurrentMonth {
            ContentUnavailableView(
                "No expenses yet",
                systemImage: "tray",
                description: Text("Tap the + button or use the “Add expense to ExpenseTracker” shortcut to get started.")
            )
        } else {
            ContentUnavailableView(
                "No expenses this month",
                systemImage: "tray",
                description: Text("Pick a different month to see other expenses.")
            )
        }
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self], inMemory: true)
}
