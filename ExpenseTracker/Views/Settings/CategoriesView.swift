import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Category.sortOrder), SortDescriptor(\Category.name)])
    private var categories: [Category]

    @State private var editing: Category?
    @State private var presentingNew = false
    @State private var deletionConflict: Category?

    var body: some View {
        List {
            ForEach(categories) { category in
                Button {
                    editing = category
                } label: {
                    HStack {
                        CategoryIcon(category: category)
                        VStack(alignment: .leading) {
                            Text(category.name)
                                .foregroundStyle(.primary)
                            Text("\(category.expenses.count) expenses")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: tryDelete)
        }
        .navigationTitle("Categories")
        .toolbar {
            Button { presentingNew = true } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $presentingNew) {
            CategoryEditor(mode: .new)
        }
        .sheet(item: $editing) { category in
            CategoryEditor(mode: .edit(category))
        }
        .alert(
            "Category in use",
            isPresented: Binding(get: { deletionConflict != nil }, set: { if !$0 { deletionConflict = nil } })
        ) {
            Button("OK", role: .cancel) { deletionConflict = nil }
        } message: {
            if let c = deletionConflict {
                Text("\"\(c.name)\" has \(c.expenses.count) expenses. Reassign them before deleting.")
            }
        }
    }

    private func tryDelete(_ offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            if !category.expenses.isEmpty {
                deletionConflict = category
                return
            }
            context.delete(category)
        }
        try? context.save()
    }
}

struct CategoryEditor: View {
    enum Mode {
        case new
        case edit(Category)
    }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    @State private var name: String = ""
    @State private var icon: String = "tag"
    @State private var colorHex: String = "#4F8EF7"

    private var title: String {
        if case .edit = mode { return "Edit Category" } else { return "New Category" }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                        ForEach(CategoryPalette.colors, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(height: 36)
                                .overlay {
                                    if hex == colorHex {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .font(.caption.bold())
                                    }
                                }
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                        ForEach(CategoryIconPalette.icons, id: \.self) { symbol in
                            ZStack {
                                Circle()
                                    .fill(symbol == icon ? Color(hex: colorHex) : Color(hex: colorHex).opacity(0.18))
                                Image(systemName: symbol)
                                    .foregroundStyle(symbol == icon ? .white : Color(hex: colorHex))
                            }
                            .frame(height: 40)
                            .onTapGesture { icon = symbol }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if case let .edit(category) = mode {
            name = category.name
            icon = category.icon
            colorHex = category.colorHex
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        switch mode {
        case .new:
            let category = Category(name: trimmed, icon: icon, colorHex: colorHex, sortOrder: Int(Date().timeIntervalSince1970))
            context.insert(category)
        case .edit(let category):
            category.name = trimmed
            category.icon = icon
            category.colorHex = colorHex
        }
        try? context.save()
        dismiss()
    }
}
