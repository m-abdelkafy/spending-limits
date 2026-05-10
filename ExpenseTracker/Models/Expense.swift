import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var date: Date
    var note: String?
    var createdAt: Date

    var category: Category?
    var account: Account?

    @Relationship(inverse: \Tag.expenses)
    var tags: [Tag]

    init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = .now,
        note: String? = nil,
        createdAt: Date = .now,
        category: Category? = nil,
        account: Account? = nil,
        tags: [Tag] = []
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
        self.createdAt = createdAt
        self.category = category
        self.account = account
        self.tags = tags
    }
}
