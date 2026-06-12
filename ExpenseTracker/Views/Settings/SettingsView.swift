import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("hideAmounts") private var hideAmounts: Bool = false

    @Query private var categories: [Category]
    @Query private var accounts: [Account]
    @Query private var tags: [Tag]
    @Query private var spendingLimits: [SpendingLimit]

    private var currentLimit: SpendingLimit? {
        let month = Budget.normalize(month: .now)
        return spendingLimits.first { Budget.normalize(month: $0.month) == month }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    Toggle(isOn: $hideAmounts) {
                        Label("Hide amounts", systemImage: "eye.slash")
                    }
                }
                Section("Spending limit") {
                    NavigationLink {
                        SpendingLimitView()
                    } label: {
                        rowLabel(
                            title: "Monthly limit",
                            systemImage: "gauge.with.dots.needle.67percent",
                            detail: currentLimit.map { CurrencyFormatter.string(from: $0.amount) } ?? "Not set"
                        )
                    }
                }
                Section("Library") {
                    NavigationLink {
                        CategoriesView()
                    } label: {
                        rowLabel(title: "Categories", systemImage: "square.grid.2x2", detail: "\(categories.count)")
                    }
                    NavigationLink {
                        AccountsView()
                    } label: {
                        rowLabel(title: "Accounts", systemImage: "creditcard", detail: "\(accounts.count)")
                    }
                    NavigationLink {
                        TagsView()
                    } label: {
                        rowLabel(title: "Tags", systemImage: "tag", detail: "\(tags.count)")
                    }
                    NavigationLink {
                        ImportExportView()
                    } label: {
                        rowLabel(title: "Import / Export", systemImage: "square.and.arrow.up.on.square", detail: nil)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    @ViewBuilder
    private func rowLabel(title: String, systemImage: String, detail: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 15))
            Spacer()
            if let detail {
                Text(detail)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self, Budget.self, SpendingLimit.self], inMemory: true)
}
