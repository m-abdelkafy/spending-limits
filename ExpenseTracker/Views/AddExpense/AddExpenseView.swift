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

    @State private var amountString: String = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var selectedTagIDs: Set<UUID> = []
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var newTagText: String = ""
    @State private var validationError: String?
    @FocusState private var amountFocused: Bool

    init(editing: Expense? = nil, onSaved: (() -> Void)? = nil) {
        self.editing = editing
        self.onSaved = onSaved
    }

    private var amountDecimal: Decimal? {
        let trimmed = amountString.replacingOccurrences(of: ",", with: ".")
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed)
    }

    private var canSave: Bool {
        guard let value = amountDecimal, value > 0 else { return false }
        return selectedCategory != nil && selectedAccount != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text(CurrencyFormatter.currencySymbol)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountString)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .focused($amountFocused)
                    }
                }

                Section("Category") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories) { category in
                                CategoryChip(
                                    category: category,
                                    isSelected: selectedCategory?.id == category.id
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Account") {
                    Picker("Account", selection: Binding(
                        get: { selectedAccount?.id },
                        set: { newID in
                            selectedAccount = accounts.first { $0.id == newID }
                        }
                    )) {
                        Text("Select…").tag(UUID?.none)
                        ForEach(accounts) { account in
                            Label(account.name, systemImage: account.type.icon)
                                .tag(Optional(account.id))
                        }
                    }
                }

                Section("Tags") {
                    TagPicker(
                        allTags: allTags,
                        selectedIDs: $selectedTagIDs,
                        newTagText: $newTagText,
                        onAddNew: addNewTag
                    )
                }

                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Note") {
                    TextField("Optional", text: $note, axis: .vertical)
                        .lineLimit(1...4)
                }

                if let error = validationError {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(editing == nil ? "New Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if editing != nil {
                        Button("Cancel") { onSaved?() ; dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let editing {
            amountString = NSDecimalNumber(decimal: editing.amount).stringValue
            selectedCategory = editing.category
            selectedAccount = editing.account
            selectedTagIDs = Set(editing.tags.map(\.id))
            date = editing.date
            note = editing.note ?? ""
        } else {
            if selectedCategory == nil { selectedCategory = categories.first }
            if selectedAccount == nil { selectedAccount = accounts.first }
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
        guard let category = selectedCategory else {
            validationError = "Pick a category."
            return
        }
        guard let account = selectedAccount else {
            validationError = "Pick an account."
            return
        }
        validationError = nil

        let chosenTags = allTags.filter { selectedTagIDs.contains($0.id) }
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let editing {
            editing.amount = amount
            editing.category = category
            editing.account = account
            editing.tags = chosenTags
            editing.date = date
            editing.note = trimmedNote.isEmpty ? nil : trimmedNote
        } else {
            let expense = Expense(
                amount: amount,
                date: date,
                note: trimmedNote.isEmpty ? nil : trimmedNote,
                category: category,
                account: account,
                tags: chosenTags
            )
            context.insert(expense)
        }

        do {
            try context.save()
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
            if editing == nil {
                resetForm()
            }
            onSaved?()
            if editing != nil { dismiss() }
        } catch {
            validationError = "Could not save: \(error.localizedDescription)"
        }
    }

    private func resetForm() {
        amountString = ""
        note = ""
        selectedTagIDs.removeAll()
        date = .now
    }
}

private struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        let color = Color(hex: category.colorHex)
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.18))
                    Image(systemName: category.icon)
                        .foregroundStyle(isSelected ? .white : color)
                        .font(.system(size: 18, weight: .semibold))
                }
                .frame(width: 48, height: 48)
                Text(category.name)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct TagPicker: View {
    let allTags: [Tag]
    @Binding var selectedIDs: Set<UUID>
    @Binding var newTagText: String
    let onAddNew: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if allTags.isEmpty {
                Text("No tags yet — add one below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(allTags) { tag in
                        TagChip(
                            name: tag.name,
                            isSelected: selectedIDs.contains(tag.id)
                        ) {
                            if selectedIDs.contains(tag.id) {
                                selectedIDs.remove(tag.id)
                            } else {
                                selectedIDs.insert(tag.id)
                            }
                        }
                    }
                }
            }

            HStack {
                TextField("New tag", text: $newTagText)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit(onAddNew)
                Button("Add", action: onAddNew)
                    .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
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
                .font(.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
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
