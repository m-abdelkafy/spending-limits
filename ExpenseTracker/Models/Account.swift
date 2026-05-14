import Foundation
import SwiftData

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case cash
    case card
    case bank
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .card: return "Card"
        case .bank: return "Bank"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .cash: return "banknote"
        case .card: return "creditcard"
        case .bank: return "building.columns"
        case .other: return "wallet.pass"
        }
    }
}

@Model
final class Account {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRaw: String
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Expense.account)
    var expenses: [Expense]

    @Relationship(deleteRule: .nullify, inverse: \Expense.toAccount)
    var transfersIn: [Expense] = []

    var type: AccountType {
        get { AccountType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        type: AccountType = .cash,
        sortOrder: Int = 0,
        expenses: [Expense] = []
    ) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.sortOrder = sortOrder
        self.expenses = expenses
    }
}
