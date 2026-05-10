import AppIntents
import SwiftData
import Foundation

// Tags are passed as freeform [String] in the intent so users can type new ones.
// This entity exists only for completeness if a future intent wants a picker.
struct TagEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Tag"
    static var defaultQuery = TagEntityQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct TagEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [TagEntity] {
        try await fetch { tags in
            tags.filter { identifiers.contains($0.id) }
                .map { TagEntity(id: $0.id, name: $0.name) }
        }
    }

    func suggestedEntities() async throws -> [TagEntity] {
        try await fetch { tags in
            tags.sorted { $0.name < $1.name }
                .map { TagEntity(id: $0.id, name: $0.name) }
        }
    }

    @MainActor
    private func fetch<T>(_ transform: ([Tag]) -> T) throws -> T {
        let context = SharedModelContainer.shared.mainContext
        let all = try context.fetch(FetchDescriptor<Tag>())
        return transform(all)
    }
}
