import Foundation

enum MonthSummary {
    static func interval(of date: Date, calendar: Calendar = .current) -> DateInterval {
        let components = calendar.dateComponents([.year, .month], from: date)
        let start = calendar.date(from: components) ?? date
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? date
        return DateInterval(start: start, end: end)
    }

    static func previousInterval(of date: Date, calendar: Calendar = .current) -> DateInterval {
        let current = interval(of: date, calendar: calendar)
        let start = calendar.date(byAdding: .month, value: -1, to: current.start) ?? current.start
        return DateInterval(start: start, end: current.start)
    }

    static func daysInMonth(of date: Date, calendar: Calendar = .current) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    static func dayOfMonth(_ date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.day, from: date)
    }

    static func filter(
        _ expenses: [Expense],
        in interval: DateInterval,
        kind: TransactionKind? = .expense
    ) -> [Expense] {
        expenses.filter { e in
            interval.contains(e.date) && (kind == nil || e.kind == kind)
        }
    }

    static func total(
        _ expenses: [Expense],
        in interval: DateInterval,
        kind: TransactionKind? = .expense
    ) -> Decimal {
        filter(expenses, in: interval, kind: kind)
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    static func dailyTotals(
        _ expenses: [Expense],
        in interval: DateInterval,
        calendar: Calendar = .current
    ) -> [Decimal] {
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 30
        var totals = Array(repeating: Decimal(0), count: days)
        for expense in expenses where expense.kind == .expense && interval.contains(expense.date) {
            let dayIndex = calendar.dateComponents([.day], from: interval.start, to: expense.date).day ?? 0
            if dayIndex >= 0 && dayIndex < days {
                totals[dayIndex] += expense.amount
            }
        }
        return totals
    }

    struct CategoryTotal: Identifiable {
        var category: Category
        var amount: Decimal
        var id: UUID { category.id }
    }

    static func byCategory(
        _ expenses: [Expense],
        in interval: DateInterval
    ) -> [CategoryTotal] {
        var bucket: [UUID: (Category, Decimal)] = [:]
        for expense in expenses where expense.kind == .expense && interval.contains(expense.date) {
            guard let category = expense.category else { continue }
            let existing = bucket[category.id]?.1 ?? 0
            bucket[category.id] = (category, existing + expense.amount)
        }
        return bucket.values
            .map { CategoryTotal(category: $0.0, amount: $0.1) }
            .sorted { $0.amount > $1.amount }
    }

    static func firstWeekdayOffset(
        of interval: DateInterval,
        calendar: Calendar = .current
    ) -> Int {
        let weekday = calendar.component(.weekday, from: interval.start)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    static func yearInterval(of date: Date, calendar: Calendar = .current) -> DateInterval {
        let components = calendar.dateComponents([.year], from: date)
        let start = calendar.date(from: components) ?? date
        let end = calendar.date(byAdding: .year, value: 1, to: start) ?? date
        return DateInterval(start: start, end: end)
    }

    static func previousYearInterval(of date: Date, calendar: Calendar = .current) -> DateInterval {
        let current = yearInterval(of: date, calendar: calendar)
        let start = calendar.date(byAdding: .year, value: -1, to: current.start) ?? current.start
        return DateInterval(start: start, end: current.start)
    }

    static func monthlyTotals(
        _ expenses: [Expense],
        in yearInterval: DateInterval,
        calendar: Calendar = .current
    ) -> [Decimal] {
        var totals = Array(repeating: Decimal(0), count: 12)
        let start = yearInterval.start
        for expense in expenses where expense.kind == .expense && yearInterval.contains(expense.date) {
            let monthIndex = calendar.dateComponents([.month], from: start, to: expense.date).month ?? 0
            if monthIndex >= 0 && monthIndex < 12 {
                totals[monthIndex] += expense.amount
            }
        }
        return totals
    }
}
