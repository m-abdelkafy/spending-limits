import AppIntents
import SwiftData
import Foundation

struct AccountEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Account"
    static var defaultQuery = AccountEntityQuery()

    var id: UUID
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct AccountEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [AccountEntity] {
        try await fetch { accounts in
            accounts
                .filter { identifiers.contains($0.id) }
                .map { AccountEntity(id: $0.id, name: $0.name) }
        }
    }

    func suggestedEntities() async throws -> [AccountEntity] {
        try await fetch { accounts in
            accounts
                .sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
                .map { AccountEntity(id: $0.id, name: $0.name) }
        }
    }

    @MainActor
    private func fetch<T>(_ transform: ([Account]) -> T) throws -> T {
        let context = SharedModelContainer.shared.mainContext
        let all = try context.fetch(FetchDescriptor<Account>())
        return transform(all)
    }
}
