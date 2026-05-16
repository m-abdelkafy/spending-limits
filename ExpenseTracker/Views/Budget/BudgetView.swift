import SwiftUI
import SwiftData

struct BudgetView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var expenses: [Expense]

    @Query private var budgets: [Budget]

    @State private var showEditor = false
    @State private var editingBudget: Budget?

    private var referenceDate: Date { .now }
    private var monthInterval: DateInterval { MonthSummary.interval(of: referenceDate) }
    private var currentMonth: Date { Budget.normalize(month: referenceDate) }

    private var monthBudgets: [Budget] {
        budgets
            .filter { Budget.normalize(month: $0.month) == currentMonth }
            .sorted { ($0.category?.sortOrder ?? 0) < ($1.category?.sortOrder ?? 0) }
    }

    private func spent(for category: Category?) -> Decimal {
        guard let category else { return 0 }
        return expenses
            .filter { $0.kind == .expense && monthInterval.contains($0.date) && $0.category?.id == category.id }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var totalLimit: Decimal {
        monthBudgets.reduce(Decimal(0)) { $0 + $1.limit }
    }

    private var totalSpent: Decimal {
        monthBudgets.reduce(Decimal(0)) { $0 + spent(for: $1.category) }
    }

    private var remaining: Decimal { totalLimit - totalSpent }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    summaryCard
                        .padding(.top, 14)

                    if monthBudgets.isEmpty {
                        emptyState
                    } else {
                        SectionHeader("By category")
                        categoryList
                    }

                    Button {
                        editingBudget = nil
                        showEditor = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Add category limit")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PrivacyToggleButton()
                }
            }
            .sheet(isPresented: $showEditor) {
                BudgetEditorView(editing: editingBudget, month: currentMonth)
            }
        }
    }

    private var summaryCard: some View {
        InsetCard(padding: EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(monthTitle) · limits")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if totalLimit > 0 {
                        HStack(spacing: 4) {
                            Text(CurrencyFormatter.string(from: totalSpent))
                                .monospacedDigit()
                                .privacyBlur()
                            Text("/")
                                .foregroundStyle(.tertiary)
                            Text(CurrencyFormatter.string(from: totalLimit))
                                .monospacedDigit()
                                .privacyBlur()
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(CurrencyFormatter.string(from: max(remaining, 0)))
                        .font(.system(size: 36, weight: .bold))
                        .monospacedDigit()
                        .privacyBlur()
                    Text(remaining >= 0 ? "left to spend" : "over budget")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var monthTitle: String {
        referenceDate.formatted(.dateTime.month(.wide))
    }

    private var categoryList: some View {
        InsetCard(padding: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)) {
            VStack(spacing: 0) {
                ForEach(Array(monthBudgets.enumerated()), id: \.element.id) { index, budget in
                    BudgetRow(
                        budget: budget,
                        spent: spent(for: budget.category)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingBudget = budget
                        showEditor = true
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            context.delete(budget)
                            try? context.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    if index != monthBudgets.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("No limits set for this month.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Tap below to add a category limit.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

private struct BudgetRow: View {
    let budget: Budget
    let spent: Decimal

    private var category: Category? { budget.category }
    private var limit: Decimal { budget.limit }
    private var progress: Double {
        guard limit > 0 else { return 0 }
        let s = NSDecimalNumber(decimal: spent).doubleValue
        let l = NSDecimalNumber(decimal: limit).doubleValue
        return s / l
    }
    private var isOver: Bool { progress > 1 }
    private var difference: Decimal { isOver ? (spent - limit) : (limit - spent) }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                CategoryTile(category: category, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(category?.name ?? "—")
                        .font(.system(size: 15, weight: .medium))
                    HStack(spacing: 0) {
                        if isOver {
                            Text("Over by ")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                            Text(CurrencyFormatter.string(from: difference))
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                                .privacyBlur()
                        } else {
                            Text(CurrencyFormatter.string(from: difference))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .privacyBlur()
                            Text(" remaining")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(CurrencyFormatter.string(from: spent))
                        .font(.system(size: 14, weight: .semibold))
                        .monospacedDigit()
                        .privacyBlur()
                    Text("of \(CurrencyFormatter.string(from: limit))")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                        .privacyBlur()
                }
            }

            ProgressBarView(
                progress: progress,
                tint: isOver ? .red : Color(hex: category?.colorHex ?? "#8E8E93"),
                showStripesWhenOver: true
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    BudgetView()
        .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self, Budget.self], inMemory: true)
}
