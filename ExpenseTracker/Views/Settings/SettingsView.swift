import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    CategoriesView()
                } label: {
                    Label("Categories", systemImage: "square.grid.2x2.fill")
                }
                NavigationLink {
                    AccountsView()
                } label: {
                    Label("Accounts", systemImage: "creditcard.fill")
                }
                NavigationLink {
                    TagsView()
                } label: {
                    Label("Tags", systemImage: "tag.fill")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
