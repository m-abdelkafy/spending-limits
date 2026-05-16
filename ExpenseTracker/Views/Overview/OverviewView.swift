import SwiftUI
import SwiftData

struct OverviewView: View {
    @Binding var selection: ContentView.Tab

    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var expenses: [Expense]

    @Query private var budgets: [Budget]

    private var referenceDate: Date { .now }
    private var calendar: Calendar { .current }
    private var monthInterval: DateInterval { MonthSummary.interval(of: referenceDate) }
    private var prevMonthInterval: DateInterval { MonthSummary.previousInterval(of: referenceDate) }

    private var totalSpent: Decimal {
        MonthSummary.total(expenses, in: monthInterval, kind: .expense)
    }

    private var prevMonthSpent: Decimal {
        MonthSummary.total(expenses, in: prevMonthInterval, kind: .expense)
    }

    private var totalBudget: Decimal {
        let currentMonth = Budget.normalize(month: referenceDate)
        return budgets.filter { Budget.normalize(month: $0.month) == currentMonth }
            .reduce(Decimal(0)) { $0 + $1.limit }
    }

    private var daysInMonth: Int { MonthSummary.daysInMonth(of: referenceDate) }
    private var dayOfMonth: Int { MonthSummary.dayOfMonth(referenceDate) }
    private var daysLeft: Int { max(0, daysInMonth - dayOfMonth) }
    private var remaining: Decimal { totalBudget - totalSpent }

    private var dailyTotals: [Decimal] {
        MonthSummary.dailyTotals(expenses, in: monthInterval)
    }

    private var categoryTotals: [MonthSummary.CategoryTotal] {
        MonthSummary.byCategory(expenses, in: monthInterval)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroBurnDownCard
                        .padding(.top, 14)

                    SectionHeader(monthTitle + " · daily spend")
                    heatmapCard

                    SectionHeader("Categories")
                    categoriesCard

                    SectionHeader("Recent", style: .uppercase) {
                        Button("See all") {
                            selection = .expenses
                        }
                        .font(.system(size: 15, weight: .regular))
                        .textCase(nil)
                    }
                    recentCard

                    Color.clear.frame(height: 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PrivacyToggleButton()
                }
            }
        }
    }

    private var monthTitle: String {
        referenceDate.formatted(.dateTime.month(.wide))
    }

    private var heroBurnDownCard: some View {
        InsetCard(padding: EdgeInsets(top: 18, leading: 18, bottom: 16, trailing: 18)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(monthTitle) · spent")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(dayOfMonth)/\(daysInMonth) days")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(CurrencyFormatter.string(from: totalSpent))
                            .font(.system(size: 40, weight: .bold))
                            .monospacedDigit()
                            .privacyBlur()
                        if totalBudget > 0 {
                            Text("of \(CurrencyFormatter.string(from: totalBudget))")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .privacyBlur()
                        }
                    }

                    ProgressBarView(
                        progress: progressValue,
                        height: .thick,
                        marker: totalBudget > 0 ? Double(dayOfMonth) / Double(daysInMonth) : nil
                    )
                }

                HStack(alignment: .top) {
                    metric(label: "Remaining", value: remainingText, alignment: .leading)
                    Spacer()
                    metric(label: "Days left", value: "\(daysLeft)", alignment: .center, blurValue: false)
                    Spacer()
                    metric(label: "Daily budget", value: dailyBudgetText, alignment: .trailing)
                }
            }
        }
    }

    private var progressValue: Double {
        guard totalBudget > 0 else { return 0 }
        let spent = NSDecimalNumber(decimal: totalSpent).doubleValue
        let limit = NSDecimalNumber(decimal: totalBudget).doubleValue
        return spent / limit
    }

    private var remainingText: String {
        CurrencyFormatter.string(from: remaining)
    }

    private var dailyBudgetText: String {
        guard daysLeft > 0, remaining > 0 else { return "—" }
        let perDay = remaining / Decimal(daysLeft)
        return CurrencyFormatter.string(from: perDay)
    }

    private func metric(label: String, value: String, alignment: HorizontalAlignment, blurValue: Bool = true) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .kerning(0.4)
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .monospacedDigit()
                .modifier(ConditionalBlur(active: blurValue))
        }
    }

    private var heatmapCard: some View {
        InsetCard {
            VStack(alignment: .leading, spacing: 12) {
                DailyHeatmapView(
                    dailyTotals: dailyTotals,
                    firstWeekdayOffset: MonthSummary.firstWeekdayOffset(of: monthInterval),
                    todayIndex: dayOfMonth - 1
                )
                HStack {
                    Text(averageLine)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .privacyBlur()
                    Spacer()
                    if prevMonthSpent > 0 {
                        comparisonBadge
                    }
                }
            }
        }
    }

    private var averageLine: String {
        let nonZeroDays = dailyTotals.prefix(dayOfMonth).filter { $0 > 0 }
        let divisor = Decimal(max(nonZeroDays.count, 1))
        let avg = nonZeroDays.reduce(Decimal(0), +) / divisor
        return "Avg \(CurrencyFormatter.string(from: avg)) / day"
    }

    private var comparisonBadge: some View {
        let spentDouble = NSDecimalNumber(decimal: totalSpent).doubleValue
        let prevDouble = NSDecimalNumber(decimal: prevMonthSpent).doubleValue
        let delta = ((spentDouble - prevDouble) / prevDouble) * 100
        let isDown = delta < 0
        return HStack(spacing: 6) {
            Text("\(isDown ? "↓" : "↑") \(Int(abs(delta)))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isDown ? .green : .orange)
            Text("vs last month")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var categoriesCard: some View {
        InsetCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 12, trailing: 16)) {
            if categoryTotals.isEmpty {
                Text("No spending this month yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 14)
            } else {
                HStack(spacing: 14) {
                    DonutChart(
                        slices: categoryTotals.map {
                            DonutSlice(
                                value: NSDecimalNumber(decimal: $0.amount).doubleValue,
                                color: Color(hex: $0.category.colorHex)
                            )
                        }
                    )
                    .overlay(donutCenter)

                    VStack(alignment: .leading, spacing: 8) {
                        let topFive = categoryTotals.prefix(5)
                        let categoriesTotal = categoryTotals.reduce(Decimal(0)) { $0 + $1.amount }
                        ForEach(Array(topFive)) { item in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: item.category.colorHex))
                                    .frame(width: 8, height: 8)
                                Text(item.category.name)
                                    .font(.system(size: 13))
                                Spacer()
                                Text(percentString(item.amount, total: categoriesTotal))
                                    .font(.system(size: 13, weight: .semibold))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }

    private var donutCenter: some View {
        let total = categoryTotals.reduce(Decimal(0)) { $0 + $1.amount }
        return VStack(spacing: 2) {
            Text("Total")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text(compactCurrency(total))
                .font(.system(size: 17, weight: .bold))
                .monospacedDigit()
                .privacyBlur()
        }
    }

    private func compactCurrency(_ value: Decimal) -> String {
        let d = NSDecimalNumber(decimal: value).doubleValue
        if d >= 1000 {
            let symbol = CurrencyFormatter.currencySymbol
            return "\(symbol)\(String(format: "%.1f", d / 1000))k"
        }
        return CurrencyFormatter.string(from: value)
    }

    private func percentString(_ amount: Decimal, total: Decimal) -> String {
        guard total > 0 else { return "0%" }
        let pct = NSDecimalNumber(decimal: amount / total).doubleValue * 100
        return "\(Int(pct.rounded()))%"
    }

    private var recentCard: some View {
        InsetCard(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
            let recent = Array(expenses.prefix(3))
            if recent.isEmpty {
                Text("No transactions yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, expense in
                        ExpenseRowView(expense: expense)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        if index != recent.count - 1 {
                            Divider().padding(.leading, 62)
                        }
                    }
                }
            }
        }
    }
}

private struct ConditionalBlur: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        if active { content.privacyBlur() } else { content }
    }
}

#Preview {
    @Previewable @State var tab: ContentView.Tab = .overview
    return OverviewView(selection: $tab)
        .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self, Budget.self], inMemory: true)
}
