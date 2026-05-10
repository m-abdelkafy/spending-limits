import SwiftUI
import SwiftData

struct TagsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Tag.name)])
    private var tags: [Tag]

    @State private var renaming: Tag?
    @State private var renameText = ""

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
            Button("Save") {
                if let tag = renaming {
                    let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        tag.name = trimmed
                        tag.normalizedName = Tag.normalize(trimmed)
                        try? context.save()
                    }
                }
                renaming = nil
            }
            Button("Cancel", role: .cancel) { renaming = nil }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            context.delete(tags[index])
        }
        try? context.save()
    }
}
