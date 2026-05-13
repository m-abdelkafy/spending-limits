import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Account.sortOrder), SortDescriptor(\Account.name)])
    private var accounts: [Account]

    @State private var editing: Account?
    @State private var presentingNew = false
    @State private var deletionConflict: Account?

    var body: some View {
        List {
            ForEach(accounts) { account in
                Button {
                    editing = account
                } label: {
                    HStack {
                        Image(systemName: account.type.icon)
                            .frame(width: 36, height: 36)
                            .background(Color.accentColor.opacity(0.15), in: Circle())
                        VStack(alignment: .leading) {
                            Text(account.name).foregroundStyle(.primary)
                            Text(account.type.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: tryDelete)
        }
        .navigationTitle("Accounts")
        .toolbar {
            Button { presentingNew = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $presentingNew) { AccountEditor(mode: .new) }
        .sheet(item: $editing) { AccountEditor(mode: .edit($0)) }
        .alert(
            "Account in use",
            isPresented: Binding(get: { deletionConflict != nil }, set: { if !$0 { deletionConflict = nil } })
        ) {
            Button("OK", role: .cancel) { deletionConflict = nil }
        } message: {
            if let a = deletionConflict {
                Text("\"\(a.name)\" has \(a.expenses.count) expenses. Reassign them before deleting.")
            }
        }
    }

    private func tryDelete(_ offsets: IndexSet) {
        for index in offsets {
            let account = accounts[index]
            if !account.expenses.isEmpty {
                deletionConflict = account
                return
            }
            context.delete(account)
        }
        try? context.save()
    }
}

struct AccountEditor: View {
    enum Mode {
        case new
        case edit(Account)
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    @State private var name = ""
    @State private var type: AccountType = .cash

    private var title: String {
        if case .edit = mode { return "Edit Account" } else { return "New Account" }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                }
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(AccountType.allCases) { t in
                            Label(t.displayName, systemImage: t.icon).tag(t)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if case let .edit(account) = mode {
            name = account.name
            type = account.type
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        switch mode {
        case .new:
            let account = Account(name: trimmed, type: type, sortOrder: Int(Date().timeIntervalSince1970))
            context.insert(account)
        case .edit(let account):
            account.name = trimmed
            account.type = type
        }
        try? context.save()
        dismiss()
    }
}
