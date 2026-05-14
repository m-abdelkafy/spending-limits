import Foundation
import SwiftData

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense
    case income
    case transfer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .transfer: return "Transfer"
        }
    }

    var icon: String {
        switch self {
        case .expense: return "arrow.up.circle.fill"
        case .income: return "arrow.down.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        }
    }
}

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var date: Date
    var note: String?
    var createdAt: Date
    var kindRaw: String

    var category: Category?
    var account: Account?
    var toAccount: Account?

    @Relationship(inverse: \Tag.expenses)
    var tags: [Tag]

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = .now,
        note: String? = nil,
        createdAt: Date = .now,
        kind: TransactionKind = .expense,
        category: Category? = nil,
        account: Account? = nil,
        toAccount: Account? = nil,
        tags: [Tag] = []
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.note = note
        self.createdAt = createdAt
        self.kindRaw = kind.rawValue
        self.category = category
        self.account = account
        self.toAccount = toAccount
        self.tags = tags
    }
}
