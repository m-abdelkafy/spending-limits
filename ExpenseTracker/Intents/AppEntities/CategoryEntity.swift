import AppIntents
import SwiftData
import Foundation

struct CategoryEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryEntityQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct CategoryEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [CategoryEntity] {
        try await fetch { categories in
            categories
                .filter { identifiers.contains($0.id) }
                .map { CategoryEntity(id: $0.id, name: $0.name) }
        }
    }

    func suggestedEntities() async throws -> [CategoryEntity] {
        try await fetch { categories in
            categories
                .sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
                .map { CategoryEntity(id: $0.id, name: $0.name) }
        }
    }

    @MainActor
    private func fetch<T>(_ transform: ([Category]) -> T) throws -> T {
        let context = SharedModelContainer.shared.mainContext
        let all = try context.fetch(FetchDescriptor<Category>())
        return transform(all)
    }
}
