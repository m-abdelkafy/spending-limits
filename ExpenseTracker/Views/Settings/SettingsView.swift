import SwiftUI

struct SettingsView: View {
    @AppStorage("hideAmounts") private var hideAmounts: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    Toggle(isOn: $hideAmounts) {
                        Label("Hide amounts", systemImage: "eye.slash.fill")
                    }
                }
                Section {
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
                    NavigationLink {
                        ImportExportView()
                    } label: {
                        Label("Import / Export", systemImage: "square.and.arrow.up.on.square.fill")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
