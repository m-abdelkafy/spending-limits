import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    let ctx = SharedModelContainer.shared.mainContext
                    SeedData.seedIfNeeded(ctx)
                    SeedData.migrateIsDefaultIfNeeded(ctx)
                }
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
