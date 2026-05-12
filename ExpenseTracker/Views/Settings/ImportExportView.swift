import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportExportView: View {
    @Environment(\.modelContext) private var context
    @Query private var expenses: [Expense]
    @Query private var categories: [Category]
    @Query private var accounts: [Account]
    @Query private var tags: [Tag]

    @State private var isShowingShareSheet = false
    @State private var isShowingFilePicker = false
    @State private var exportURLs: [URL] = []
    @State private var importResult: ImportResult?
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Button {
                    exportData()
                } label: {
                    Label("Export All Data", systemImage: "square.and.arrow.up")
                }

                Button {
                    isShowingFilePicker = true
                } label: {
                    Label("Import from Backup", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("Export produces 4 CSV files: expenses, categories, accounts, and tags. Select all 4 when importing.")
            }
        }
        .navigationTitle("Import / Export")
        .background(
            ActivityPresenter(urls: exportURLs, isPresented: $isShowingShareSheet)
        )
        .sheet(isPresented: $isShowingFilePicker) {
            DocumentPicker(types: [.commaSeparatedText]) { urls in
                importData(from: urls)
            }
            .ignoresSafeArea()
        }
        .alert("Import Complete", isPresented: Binding(
            get: { importResult != nil },
            set: { if !$0 { importResult = nil } }
        )) {
            Button("OK") { importResult = nil }
        } message: {
            if let result = importResult {
                Text("Imported \(result.summary).")
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            if let msg = errorMessage {
                Text(msg)
            }
        }
    }

    // MARK: - Actions

    private func exportData() {
        do {
            let exporter = DataExporter()
            exportURLs = try exporter.export(
                accounts: accounts,
                categories: categories,
                tags: tags,
                expenses: expenses
            )
            isShowingShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importData(from urls: [URL]) {
        guard !urls.isEmpty else { return }
        do {
            let importer = DataImporter()
            importResult = try importer.importData(from: urls, into: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - UIKit wrappers

/// Presents UIActivityViewController from a hidden UIViewController in the background,
/// avoiding the blank-sheet bug that occurs when wrapping it directly in a SwiftUI .sheet.
private struct ActivityPresenter: UIViewControllerRepresentable {
    let urls: [URL]
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented, uiViewController.presentedViewController == nil else { return }
        let vc = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in isPresented = false }
        uiViewController.present(vc, animated: true)
    }
}

private struct DocumentPicker: UIViewControllerRepresentable {
    let types: [UTType]
    let onPick: ([URL]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void
        init(onPick: @escaping ([URL]) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let secured = urls.map { url -> URL in
                _ = url.startAccessingSecurityScopedResource()
                return url
            }
            onPick(secured)
            secured.forEach { $0.stopAccessingSecurityScopedResource() }
        }
    }
}
