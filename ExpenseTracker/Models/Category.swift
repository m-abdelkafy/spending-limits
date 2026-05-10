import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "tag",
        colorHex: String = "#4F8EF7",
        sortOrder: Int = 0,
        expenses: [Expense] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.expenses = expenses
    }
}
