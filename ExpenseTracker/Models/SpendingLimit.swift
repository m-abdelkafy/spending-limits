import Foundation
import SwiftData

@Model
final class SpendingLimit {
    @Attribute(.unique) var id: UUID
    var month: Date
    var amount: Decimal

    init(
        id: UUID = UUID(),
        month: Date,
        amount: Decimal
    ) {
        self.id = id
        self.month = Budget.normalize(month: month)
        self.amount = amount
    }

    /// Returns the limit whose stored month matches the given month after
    /// normalization. Stored months are normalized at construction, so
    /// equality is sufficient on the lookup side.
    static func limit(for month: Date, in limits: [SpendingLimit]) -> SpendingLimit? {
        let normalized = Budget.normalize(month: month)
        return limits.first { $0.month == normalized }
    }
}
