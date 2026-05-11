import SwiftUI
import SwiftData

struct TagsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Tag.name)])
    private var tags: [Tag]

    @State private var renaming: Tag?
    @State private var renameText = ""
    @State private var renameError: String?

    var body: some View {
        List {
            if tags.isEmpty {
                ContentUnavailableView(
                    "No tags yet",
                    systemImage: "tag",
                    description: Text("Tags appear here once you create one from an expense or via Shortcuts.")
                )
            } else {
                ForEach(tags) { tag in
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundStyle(.secondary)
                        Text(tag.name)
                        Spacer()
                        Text("\(tag.expenses.count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        renameText = tag.name
                        renaming = tag
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Tags")
        .alert("Rename tag", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $renameText)
            Button("Save") { commitRename() }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
        .alert(
            "Couldn’t rename tag",
            isPresented: Binding(get: { renameError != nil }, set: { if !$0 { renameError = nil } })
        ) {
            Button("OK", role: .cancel) { renameError = nil }
        } message: {
            Text(renameError ?? "")
        }
    }

    private func commitRename() {
        guard let tag = renaming else { return }
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            renaming = nil
            return
        }
        let normalized = Tag.normalize(trimmed)

        // No-op rename — same name (possibly different casing) on the same tag.
        if normalized == tag.normalizedName {
            tag.name = trimmed
            saveOrFail(tag: tag, originalName: tag.name, originalNormalized: tag.normalizedName)
            renaming = nil
            return
        }

        // Reject if another tag already owns this normalized name.
        if tags.contains(where: { $0.id != tag.id && $0.normalizedName == normalized }) {
            renameError = "A tag named “\(trimmed)” already exists."
            return
        }

        let originalName = tag.name
        let originalNormalized = tag.normalizedName
        tag.name = trimmed
        tag.normalizedName = normalized
        saveOrFail(tag: tag, originalName: originalName, originalNormalized: originalNormalized)
        renaming = nil
    }

    private func saveOrFail(tag: Tag, originalName: String, originalNormalized: String) {
        do {
            try context.save()
        } catch {
            tag.name = originalName
            tag.normalizedName = originalNormalized
            renameError = error.localizedDescription
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(tags[index])
        }
        try? context.save()
    }
}
