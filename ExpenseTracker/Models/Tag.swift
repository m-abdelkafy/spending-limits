import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var id: UUID
    var name: String
    @Attribute(.unique) var normalizedName: String

    var expenses: [Expense]

    init(
        id: UUID = UUID(),
        name: String,
        expenses: [Expense] = []
    ) {
        self.id = id
        self.name = name
        self.normalizedName = Tag.normalize(name)
        self.expenses = expenses
    }

    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
