import SwiftUI

struct BudgetView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Budget",
                systemImage: "chart.bar",
                description: Text("Coming soon.")
            )
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PrivacyToggleButton()
                }
            }
        }
    }
}

#Preview {
    BudgetView()
}
