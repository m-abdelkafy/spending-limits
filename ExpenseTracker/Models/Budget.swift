import Foundation
import SwiftData

@Model
final class Budget {
    @Attribute(.unique) var id: UUID
    var month: Date
    var limit: Decimal
    var category: Category?

    init(
        id: UUID = UUID(),
        month: Date,
        limit: Decimal,
        category: Category? = nil
    ) {
        self.id = id
        self.month = Budget.normalize(month: month)
        self.limit = limit
        self.category = category
    }

    static func normalize(month date: Date, calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
}
