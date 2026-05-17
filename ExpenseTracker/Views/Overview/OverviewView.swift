import SwiftUI
import SwiftData

struct OverviewView: View {
    @Binding var selection: ContentView.Tab

    @Query(sort: [SortDescriptor(\Expense.date, order: .reverse)])
    private var allExpenses: [Expense]

    @Query private var allBudgets: [Budget]

    @State private var range: DateRange = .currentMonth()

    init(selection: Binding<ContentView.Tab>) {
        _selection = selection
    }

    private var calendar: Calendar { .current }
    private var rangeInterval: DateInterval { range.interval() }
    private var previousInterval: DateInterval { range.previousInterval() }

    private var rangeExpenses: [Expense] {
        allExpenses.filter { rangeInterval.contains($0.date) }
    }

    private var totalSpent: Decimal {
        MonthSummary.total(allExpenses, in: rangeInterval, kind: .expense)
    }

    private var previousSpent: Decimal {
        MonthSummary.total(allExpenses, in: previousInterval, kind: .expense)
    }

    private var totalBudget: Decimal {
        switch range.scope {
        case .month:
            let normalized = Budget.normalize(month: range.anchor)
            return allBudgets
                .filter { Budget.normalize(month: $0.month) == normalized }
                .reduce(Decimal(0)) { $0 + $1.limit }
        case .year:
            let year = calendar.component(.year, from: range.anchor)
            return allBudgets
                .filter { calendar.component(.year, from: $0.month) == year }
                .reduce(Decimal(0)) { $0 + $1.limit }
        }
    }

    private var remaining: Decimal { totalBudget - totalSpent }

    private var isCurrentRange: Bool { range.isCurrent() }

    private var dailyTotals: [Decimal] {
        MonthSummary.dailyTotals(allExpenses, in: rangeInterval)
    }

    private var monthlyTotals: [Decimal] {
        MonthSummary.monthlyTotals(allExpenses, in: rangeInterval)
    }

    private var categoryTotals: [MonthSummary.CategoryTotal] {
        MonthSummary.byCategory(allExpenses, in: rangeInterval)
    }

    private var daysInMonth: Int { MonthSummary.daysInMonth(of: range.anchor) }
    private var dayOfMonth: Int { MonthSummary.dayOfMonth(.now) }
    private var daysLeft: Int { max(daysInMonth - dayOfMonth + 1, 0) }
    private var currentMonthIndexInYear: Int? {
        guard range.scope == .year, isCurrentRange else { return nil }
        return calendar.component(.month, from: .now) - 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    rangePickerBar
                        .padding(.top, 8)

                    heroCard
                        .padding(.top, 8)

                    SectionHeader(secondaryHeaderTitle)
                    secondaryChartCard

                    SectionHeader("Categories")
                    categoriesCard

                    SectionHeader(title: "Recent", style: .uppercase) {
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

    private var rangePickerBar: some View {
        RangePickerView(range: $range)
            .padding(.horizontal, 16)
    }

    private var heroCard: some View {
        InsetCard(padding: EdgeInsets(top: 18, leading: 18, bottom: 16, trailing: 18)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(range.title()) · spent")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let progressLabel {
                        Text(progressLabel)
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
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
                        marker: progressMarker
                    )
                }

                heroMetricsRow
            }
        }
    }

    @ViewBuilder
    private var heroMetricsRow: some View {
        switch range.scope {
        case .month where isCurrentRange:
            HStack(alignment: .top) {
                metric(label: "Remaining", value: remainingText, alignment: .leading)
                Spacer()
                metric(label: "Days left", value: "\(daysLeft)", alignment: .center, blurValue: false)
                Spacer()
                metric(label: "Daily budget", value: dailyBudgetText, alignment: .trailing)
            }
        case .month:
            HStack(alignment: .top) {
                metric(label: "Remaining", value: remainingText, alignment: .leading)
                Spacer()
                metric(label: "Avg / day", value: monthlyAvgPerDayText, alignment: .trailing)
            }
        case .year:
            HStack(alignment: .top) {
                metric(label: "Remaining", value: remainingText, alignment: .leading)
                Spacer()
                metric(label: "Avg / month", value: yearlyAvgPerMonthText, alignment: .trailing)
            }
        }
    }

    private var progressLabel: String? {
        switch range.scope {
        case .month where isCurrentRange:
            return "\(dayOfMonth)/\(daysInMonth) days"
        case .month:
            return "\(daysInMonth) days"
        case .year where isCurrentRange:
            return "Month \(calendar.component(.month, from: .now))/12"
        case .year:
            return "Full year"
        }
    }

    private var progressMarker: Double? {
        guard totalBudget > 0, isCurrentRange else { return nil }
        switch range.scope {
        case .month:
            return Double(dayOfMonth) / Double(daysInMonth)
        case .year:
            let monthNow = calendar.component(.month, from: .now)
            return Double(monthNow - 1) / 12.0
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

    private var monthlyAvgPerDayText: String {
        let divisor = Decimal(max(daysInMonth, 1))
        return CurrencyFormatter.string(from: totalSpent / divisor)
    }

    private var yearlyAvgPerMonthText: String {
        let monthsElapsed: Int
        if isCurrentRange {
            monthsElapsed = max(calendar.component(.month, from: .now), 1)
        } else {
            monthsElapsed = 12
        }
        return CurrencyFormatter.string(from: totalSpent / Decimal(monthsElapsed))
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

    private var secondaryHeaderTitle: String {
        switch range.scope {
        case .month: "\(range.title()) · daily spend"
        case .year: "\(range.title()) · monthly spend"
        }
    }

    @ViewBuilder
    private var secondaryChartCard: some View {
        InsetCard {
            VStack(alignment: .leading, spacing: 12) {
                switch range.scope {
                case .month:
                    DailyHeatmapView(
                        dailyTotals: dailyTotals,
                        firstWeekdayOffset: MonthSummary.firstWeekdayOffset(of: rangeInterval),
                        todayIndex: isCurrentRange ? (dayOfMonth - 1) : nil
                    )
                case .year:
                    MonthlyBarsView(
                        monthlyTotals: monthlyTotals,
                        currentMonthIndex: currentMonthIndexInYear
                    )
                }

                HStack {
                    Text(averageLine)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .privacyBlur()
                    Spacer()
                    if previousSpent > 0 {
                        comparisonBadge
                    }
                }
            }
        }
    }

    private var averageLine: String {
        switch range.scope {
        case .month:
            let upper = isCurrentRange ? dayOfMonth : dailyTotals.count
            let nonZeroDays = dailyTotals.prefix(upper).filter { $0 > 0 }
            let divisor = Decimal(max(nonZeroDays.count, 1))
            let avg = nonZeroDays.reduce(Decimal(0), +) / divisor
            return "Avg \(CurrencyFormatter.string(from: avg)) / day"
        case .year:
            let upper = isCurrentRange ? calendar.component(.month, from: .now) : 12
            let nonZeroMonths = monthlyTotals.prefix(upper).filter { $0 > 0 }
            let divisor = Decimal(max(nonZeroMonths.count, 1))
            let avg = nonZeroMonths.reduce(Decimal(0), +) / divisor
            return "Avg \(CurrencyFormatter.string(from: avg)) / month"
        }
    }

    @ViewBuilder
    private var comparisonBadge: some View {
        let spentDouble = NSDecimalNumber(decimal: totalSpent).doubleValue
        let prevDouble = NSDecimalNumber(decimal: previousSpent).doubleValue
        if prevDouble > 0 {
            let delta = ((spentDouble - prevDouble) / prevDouble) * 100
            let isDown = delta < 0
            HStack(spacing: 6) {
                Text("\(isDown ? "↓" : "↑") \(Int(abs(delta)))%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isDown ? .green : .orange)
                Text(comparisonSuffix)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var comparisonSuffix: String {
        switch range.scope {
        case .month: "vs previous month"
        case .year: "vs previous year"
        }
    }

    @ViewBuilder
    private var categoriesCard: some View {
        InsetCard(padding: EdgeInsets(top: 16, leading: 16, bottom: 12, trailing: 16)) {
            if categoryTotals.isEmpty {
                Text(emptyCategoriesText)
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

    private var emptyCategoriesText: String {
        switch range.scope {
        case .month: "No spending this month yet."
        case .year: "No spending this year yet."
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
            let recent = Array(rangeExpenses.prefix(3))
            if recent.isEmpty {
                Text("No transactions in this range.")
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

#Preview {
    @Previewable @State var tab: ContentView.Tab = .overview
    return OverviewView(selection: $tab)
        .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self, Budget.self], inMemory: true)
}
