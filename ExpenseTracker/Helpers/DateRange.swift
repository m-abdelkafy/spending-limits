import Foundation

enum DateRangeScope: String, CaseIterable, Hashable {
    case month, year

    var label: String {
        switch self {
        case .month: "Month"
        case .year: "Year"
        }
    }
}

struct DateRange: Equatable, Hashable {
    var scope: DateRangeScope
    var anchor: Date

    static func currentMonth(calendar: Calendar = .current) -> DateRange {
        DateRange(scope: .month, anchor: Budget.normalize(month: .now, calendar: calendar))
    }

    func interval(calendar: Calendar = .current) -> DateInterval {
        switch scope {
        case .month: MonthSummary.interval(of: anchor, calendar: calendar)
        case .year: MonthSummary.yearInterval(of: anchor, calendar: calendar)
        }
    }

    func previousInterval(calendar: Calendar = .current) -> DateInterval {
        switch scope {
        case .month: MonthSummary.previousInterval(of: anchor, calendar: calendar)
        case .year: MonthSummary.previousYearInterval(of: anchor, calendar: calendar)
        }
    }

    func title(calendar: Calendar = .current) -> String {
        switch scope {
        case .month:
            let currentYear = calendar.component(.year, from: .now)
            let anchorYear = calendar.component(.year, from: anchor)
            return anchorYear == currentYear
                ? anchor.formatted(.dateTime.month(.wide))
                : anchor.formatted(.dateTime.month(.wide).year())
        case .year:
            return String(calendar.component(.year, from: anchor))
        }
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        interval(calendar: calendar).contains(date)
    }

    func isCurrent(calendar: Calendar = .current) -> Bool {
        switch scope {
        case .month: calendar.isDate(anchor, equalTo: .now, toGranularity: .month)
        case .year: calendar.isDate(anchor, equalTo: .now, toGranularity: .year)
        }
    }
}
