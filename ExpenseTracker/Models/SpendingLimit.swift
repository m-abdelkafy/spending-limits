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
}
