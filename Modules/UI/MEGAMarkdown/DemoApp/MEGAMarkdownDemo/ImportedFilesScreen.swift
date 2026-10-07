import SwiftUI

/// Lists the imported files. A file opens at the line it showed last time.
struct ImportedFilesScreen: View {
    @State private var entries = ImportedFiles.entries()

    var body: some View {
        List {
            ForEach(entries) { entry in
                NavigationLink(value: entry) {
                    LabeledContent {
                        Text(entry.byteCount.formatted(.byteCount(style: .file)))
                    } label: {
                        Label(entry.name, systemImage: "doc.text")
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    try? FileManager.default.removeItem(at: entries[index].url)
                }
                entries = ImportedFiles.entries()
            }
        }
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No imported files",
                    systemImage: "square.and.arrow.down",
                    description: Text("In the Files app or in MEGA, share a Markdown file and choose this app.")
                )
            }
        }
        .navigationTitle("Imported files")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { entries = ImportedFiles.entries() }
    }
}
