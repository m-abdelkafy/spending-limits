import Foundation
import SwiftData

enum SeedData {
    struct DefaultCategory {
        let name: String
        let icon: String
        let colorHex: String
    }

    static let categories: [DefaultCategory] = [
        .init(name: "Food", icon: "fork.knife", colorHex: "#FF6B6B"),
        .init(name: "Transport", icon: "car.fill", colorHex: "#4F8EF7"),
        .init(name: "Bills", icon: "doc.text.fill", colorHex: "#9B59B6"),
        .init(name: "Entertainment", icon: "popcorn.fill", colorHex: "#F39C12"),
        .init(name: "Shopping", icon: "bag.fill", colorHex: "#1ABC9C"),
        .init(name: "Health", icon: "heart.fill", colorHex: "#E74C3C"),
    ]

    static let accounts: [(name: String, type: AccountType)] = [
        ("Cash", .cash),
        ("Card", .card),
        ("Bank", .bank),
    ]

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let categoryFetch = FetchDescriptor<Category>()
        let existingCategories = (try? context.fetchCount(categoryFetch)) ?? 0
        if existingCategories == 0 {
            for (index, def) in categories.enumerated() {
                let cat = Category(
                    name: def.name,
                    icon: def.icon,
                    colorHex: def.colorHex,
                    sortOrder: index
                )
                context.insert(cat)
            }
        }

        let accountFetch = FetchDescriptor<Account>()
        let existingAccounts = (try? context.fetchCount(accountFetch)) ?? 0
        if existingAccounts == 0 {
            for (index, def) in accounts.enumerated() {
                let acc = Account(name: def.name, type: def.type, sortOrder: index)
                context.insert(acc)
            }
        }

        try? context.save()
    }
}
