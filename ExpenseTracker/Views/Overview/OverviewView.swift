import SwiftUI

struct OverviewView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Overview",
                systemImage: "chart.pie",
                description: Text("Coming soon.")
            )
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PrivacyToggleButton()
                }
            }
        }
    }
}

#Preview {
    OverviewView()
}
