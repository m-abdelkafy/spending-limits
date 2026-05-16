import SwiftUI

struct ContentView: View {
    @State private var selection: Tab = .expenses

    enum Tab: Hashable {
        case overview, expenses, budget, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            OverviewView()
                .tabItem {
                    Label("Overview", systemImage: "chart.pie.fill")
                }
                .tag(Tab.overview)

            ExpenseListView()
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.expenses)

            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "chart.bar.fill")
                }
                .tag(Tab.budget)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self], inMemory: true)
}
