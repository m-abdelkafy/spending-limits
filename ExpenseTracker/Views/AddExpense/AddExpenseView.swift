import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: [SortDescriptor(\Category.sortOrder), SortDescriptor(\Category.name)])
    private var categories: [Category]
    @Query(sort: [SortDescriptor(\Account.sortOrder), SortDescriptor(\Account.name)])
    private var accounts: [Account]
    @Query(sort: [SortDescriptor(\Tag.name)])
    private var allTags: [Tag]

    private let editing: Expense?
    private let onSaved: (() -> Void)?

    @State private var kind: TransactionKind = .expense
    @State private var amountString: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var selectedToAccount: Account?
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var newTagText: String = ""
    @State private var validationError: String?
    @State private var showCategoryPicker = false
    @FocusState private var amountFocused: Bool

    init(editing: Expense? = nil, onSaved: (() -> Void)? = nil) {
        self.editing = editing
        self.onSaved = onSaved
    }

    private var amountDecimal: Decimal? {
        DecimalInput.parse(amountString)
    }

    private var availableKinds: [TransactionKind] {
        accounts.count >= 2
            ? TransactionKind.allCases
            : TransactionKind.allCases.filter { $0 != .transfer }
    }

    private var canSave: Bool {
        guard let value = amountDecimal, value > 0 else { return false }
        switch kind {
        case .expense, .income:
            return selectedCategory != nil && selectedAccount != nil
        case .transfer:
            guard let from = selectedAccount, let to = selectedToAccount else { return false }
            return from.id != to.id
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    typePickerSection
                    amountCard
                    detailsCard
                    if !allTags.isEmpty || !selectedTagIDs.isEmpty {
                        SectionHeader("Tags")
                        tagsCard
                    }
                    SectionHeader("Note")
                    noteCard
                    if let error = validationError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                    }
                    Color.clear.frame(height: 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onSaved?() ; dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selection: $selectedCategory)
            }
            .onAppear(perform: load)
        }
    }

    private var typePickerSection: some View {
        Picker("Type", selection: $kind) {
            ForEach(availableKinds) { k in
                Text(k.displayName).tag(k)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .onChange(of: accounts.count) { _, newValue in
            if newValue < 2 && kind == .transfer { kind = .expense }
        }
    }

    private var amountCard: some View {
        InsetCard(padding: EdgeInsets(top: 14, leading: 18, bottom: 16, trailing: 18)) {
            VStack(alignment: .leading, spacing: 6) {
                Text("AMOUNT")
                    .font(.system(size: 11, weight: .semibold))
                    .kerning(0.4)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(CurrencyFormatter.currencySymbol)
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    TextField("0", text: $amountString)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 42, weight: .semibold))
                        .monospacedDigit()
                        .focused($amountFocused)
                }
            }
        }
        .padding(.top, 14)
    }

    private var detailsCard: some View {
        InsetCard(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
            VStack(spacing: 0) {
                if kind != .transfer {
                    categoryRow
                    Divider().padding(.leading, 14)
                }
                accountRow(label: kind == .transfer ? "From" : "Account", binding: $selectedAccount)
                if kind == .transfer {
                    Divider().padding(.leading, 14)
                    accountRow(label: "To", binding: $selectedToAccount)
                }
                Divider().padding(.leading, 14)
                dateRow
            }
        }
        .padding(.top, 14)
    }

    private var categoryRow: some View {
        Button {
            showCategoryPicker = true
        } label: {
            HStack(spacing: 12) {
                Text("Category")
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                Spacer()
                if let category = selectedCategory {
                    CategoryTile(category: category, size: 24)
                    Text(category.name)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Choose")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func accountRow(label: String, binding: Binding<Account?>) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 15))
            Spacer()
            Menu {
                ForEach(accounts) { account in
                    Button {
                        binding.wrappedValue = account
                    } label: {
                        Label(account.name, systemImage: account.type.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    if let acc = binding.wrappedValue {
                        Image(systemName: acc.type.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Text(acc.name)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Choose")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var dateRow: some View {
        HStack(spacing: 12) {
            Text("Date")
                .font(.system(size: 15))
            Spacer()
            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var tagsCard: some View {
        InsetCard(padding: EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)) {
            VStack(alignment: .leading, spacing: 12) {
                if !allTags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(allTags) { tag in
                            TagChip(name: tag.name, isSelected: selectedTagIDs.contains(tag.id)) {
                                if selectedTagIDs.contains(tag.id) {
                                    selectedTagIDs.remove(tag.id)
                                } else {
                                    selectedTagIDs.insert(tag.id)
                                }
                            }
                        }
                    }
                }
                HStack {
                    TextField("New tag", text: $newTagText)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .onSubmit(addNewTag)
                    Button("Add", action: addNewTag)
                        .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var noteCard: some View {
        InsetCard(padding: EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)) {
            TextField("Optional", text: $note, axis: .vertical)
                .lineLimit(1...4)
                .font(.system(size: 15))
        }
    }

    private var navigationTitle: String {
        if editing != nil {
            return "Edit \(kind.displayName)"
        }
        return "New \(kind.displayName)"
    }

    private func load() {
        if let editing {
            kind = editing.kind
            amountString = NSDecimalNumber(decimal: editing.amount).stringValue
            selectedCategory = editing.category
            selectedAccount = editing.account
            selectedToAccount = editing.toAccount
            selectedTagIDs = Set(editing.tags.map(\.id))
            date = editing.date
            note = editing.note ?? ""
        } else {
            if selectedCategory == nil { selectedCategory = categories.first { $0.isDefault } ?? categories.first }
            if selectedAccount == nil { selectedAccount = accounts.first }
            if selectedToAccount == nil {
                selectedToAccount = accounts.first { $0.id != selectedAccount?.id }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                amountFocused = true
            }
        }
    }

    private func addNewTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let normalized = Tag.normalize(trimmed)
        if let existing = allTags.first(where: { $0.normalizedName == normalized }) {
            selectedTagIDs.insert(existing.id)
        } else {
            let tag = Tag(name: trimmed)
            context.insert(tag)
            try? context.save()
            selectedTagIDs.insert(tag.id)
        }
        newTagText = ""
    }

    private func save() {
        guard let amount = amountDecimal, amount > 0 else {
            validationError = "Enter an amount greater than zero."
            return
        }
        guard let account = selectedAccount else {
            validationError = kind == .transfer ? "Pick a source account." : "Pick an account."
            return
        }

        let category: Category?
        let toAccount: Account?
        switch kind {
        case .expense, .income:
            guard let chosen = selectedCategory else {
                validationError = "Pick a category."
                return
            }
            category = chosen
            toAccount = nil
        case .transfer:
            guard let dest = selectedToAccount else {
                validationError = "Pick a destination account."
                return
            }
            guard dest.id != account.id else {
                validationError = "From and To must be different accounts."
                return
            }
            category = nil
            toAccount = dest
        }
        validationError = nil

        let chosenTags = allTags.filter { selectedTagIDs.contains($0.id) }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editing {
            editing.amount = amount
            editing.kind = kind
            editing.category = category
            editing.account = account
            editing.toAccount = toAccount
            editing.tags = chosenTags
            editing.date = date
            editing.note = trimmedNote.isEmpty ? nil : trimmedNote
        } else {
            let expense = Expense(
                amount: amount,
                date: date,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                kind: kind,
                category: category,
                account: account,
                toAccount: toAccount,
                tags: chosenTags
            )
            context.insert(expense)
        }

        do {
            try context.save()
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            onSaved?()
            dismiss()
        } catch {
            validationError = "Could not save: \(error.localizedDescription)"
        }
    }
}

private struct TagChip: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("#\(name)")
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.18))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x)
        }
        return CGSize(width: totalWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
