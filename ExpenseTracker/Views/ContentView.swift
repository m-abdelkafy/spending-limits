import SwiftUI

struct ContentView: View {
    @State private var selection: Tab = .expenses

    enum Tab: Hashable {
        case expenses, add, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            ExpenseListView()
                .tabItem {
                    Label("Expenses", systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.expenses)

            AddExpenseView(onSaved: { selection = .expenses })
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(Tab.add)

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
