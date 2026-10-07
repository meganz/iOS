import SwiftUI

/// The first screen: one entry for each Preview feature.
struct RootView: View {
    @State private var path = NavigationPath()
    @State private var isShowingSettings = false
    @State private var importError: String?

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("Preview") {
                    NavigationLink("Imported files", value: DemoRoute.imported)
                    NavigationLink("Open at a line", value: DemoRoute.openAtLine)
                    NavigationLink("Switch text in one preview", value: DemoRoute.switchText)
                }
                Section("Test cases") {
                    if let root = TestFileEntry.root {
                        NavigationLink("Images", value: TestFileEntry.folder(root.appending(path: "images")))
                        NavigationLink("Large files", value: TestFileEntry.folder(root.appending(path: "large-files")))
                    }
                    NavigationLink("All test files", value: DemoRoute.testFiles)
                }
            }
            .navigationTitle("Markdown demo")
            .toolbar {
                Button("Settings", systemImage: "gearshape") {
                    isShowingSettings = true
                }
            }
            .navigationDestination(for: DemoRoute.self) { route in
                switch route {
                case .imported: ImportedFilesScreen()
                case .openAtLine: OpenAtLineScreen()
                case .switchText: SwitchTextScreen()
                case .testFiles: TestFilesScreen()
                }
            }
            .navigationDestination(for: OpenAtLine.self) { target in
                FileScreen(entry: target.entry, restoreLine: target.line == 0 ? nil : target.line)
            }
            .navigationDestination(for: TestFileEntry.self) { entry in
                if entry.isFolder {
                    FolderView(folder: entry.url, title: entry.name)
                } else if entry.isImage {
                    ImageFileView(entry: entry)
                } else {
                    FileScreen(entry: entry)
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        // Another app shares a Markdown file with the demo.
        .onOpenURL { url in
            do {
                guard ImportedFiles.isMarkdown(url) else {
                    importError = "\(url.lastPathComponent) is not a Markdown file."
                    return
                }
                let copy = try ImportedFiles.importFile(from: url)
                path.append(ImportedFiles.entry(for: copy))
            } catch {
                importError = error.localizedDescription
            }
        }
        .alert("Import failed", isPresented: Binding(get: { importError != nil }, set: { _ in importError = nil })) {
            Button("OK") {}
        } message: {
            Text(importError ?? "")
        }
    }
}

enum DemoRoute: Hashable {
    case imported
    case openAtLine
    case switchText
    case testFiles
}
