import SwiftUI

struct ContentView: View {
    @State private var selection: Tab = .overview

    enum Tab: Hashable {
        case overview, expenses, budget, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            OverviewView(selection: $selection)
                .tabItem {
                    Label("Overview", systemImage: "chart.pie")
                }
                .tag(Tab.overview)

            ExpenseListView()
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet")
                }
                .tag(Tab.expenses)

            BudgetView()
                .tabItem {
                    Label("Budget", systemImage: "chart.bar")
                }
                .tag(Tab.budget)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self, Budget.self, SpendingLimit.self], inMemory: true)
}
