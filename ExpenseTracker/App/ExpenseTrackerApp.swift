import SwiftUI
import SwiftData

@main
struct ExpenseTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    SeedData.seedIfNeeded(SharedModelContainer.shared.mainContext)
                }
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
