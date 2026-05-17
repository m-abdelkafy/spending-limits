import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var sortOrder: Int
    var isDefault: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense]

    @Relationship(deleteRule: .cascade, inverse: \Budget.category)
    var budgets: [Budget] = []

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "tag",
        colorHex: String = "#4F8EF7",
        sortOrder: Int = 0,
        isDefault: Bool = false,
        expenses: [Expense] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.expenses = expenses
    }
}
