import Foundation
import SwiftData

enum SharedModelContainer {
    static let schema = Schema([
        Expense.self,
        Category.self,
        Account.self,
        Tag.self,
        Budget.self,
    ])

    static let shared: ModelContainer = {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()
}
