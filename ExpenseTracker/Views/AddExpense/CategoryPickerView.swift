import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: [SortDescriptor(\Category.sortOrder), SortDescriptor(\Category.name)])
    private var allCategories: [Category]

    @Binding var selection: Category?
    var restrictTo: [Category]? = nil

    @State private var query = ""
    @State private var showCreate = false

    private var categories: [Category] {
        if let restrictTo {
            let ids = Set(restrictTo.map(\.id))
            return allCategories.filter { ids.contains($0.id) }
        }
        return allCategories
    }

    private var filtered: [Category] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty { return categories }
        return categories.filter { $0.name.lowercased().contains(trimmed) }
    }

    private var defaults: [Category] { filtered.filter { $0.isDefault } }
    private var custom: [Category] { filtered.filter { !$0.isDefault } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if !defaults.isEmpty {
                        SectionHeader("Default")
                        section(items: defaults)
                    }
                    if !custom.isEmpty {
                        SectionHeader("Custom")
                        section(items: custom)
                    }
                    if defaults.isEmpty && custom.isEmpty {
                        Text("No categories match \"\(query)\".")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    }
                    Color.clear.frame(height: 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: searchPrompt)
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("New") { showCreate = true }
                }
            }
            .sheet(isPresented: $showCreate) {
                NewCategoryView { created in
                    selection = created
                    dismiss()
                }
            }
        }
    }

    private var searchPrompt: String {
        "Search \(categories.count) categories"
    }

    private func section(items: [Category]) -> some View {
        InsetCard(padding: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, category in
                    Button {
                        selection = category
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            CategoryTile(category: category, size: 32)
                            Text(category.name)
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)
                            Spacer()
                            if selection?.id == category.id {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                    }
                    .buttonStyle(.plain)
                    if index != items.count - 1 {
                        Divider().padding(.leading, 58)
                    }
                }
            }
        }
    }
}

private struct NewCategoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: [SortDescriptor(\Category.sortOrder, order: .reverse)])
    private var existing: [Category]

    let onCreated: (Category) -> Void

    @State private var name: String = ""
    @State private var colorHex: String = CategoryPalette.colors.first ?? "#4F8EF7"
    @State private var icon: String = CategoryIconPalette.icons.first ?? "tag"

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Category name", text: $name)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(CategoryPalette.colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(colorHex == hex ? 1 : 0), lineWidth: 2)
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(CategoryIconPalette.icons, id: \.self) { symbol in
                            Image(systemName: symbol)
                                .font(.system(size: 18, weight: .semibold))
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(icon == symbol ? Color.accentColor.opacity(0.2) : Color.clear)
                                )
                                .foregroundStyle(icon == symbol ? Color.accentColor : Color.primary)
                                .onTapGesture { icon = symbol }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextOrder = (existing.first?.sortOrder ?? 0) + 1
        let category = Category(
            name: trimmed,
            icon: icon,
            colorHex: colorHex,
            sortOrder: nextOrder,
            isDefault: false
        )
        context.insert(category)
        try? context.save()
        onCreated(category)
        dismiss()
    }
}

#Preview {
    @Previewable @State var selection: Category?
    return CategoryPickerView(selection: $selection)
        .modelContainer(for: [Expense.self, Category.self, Account.self, Tag.self, Budget.self], inMemory: true)
}
