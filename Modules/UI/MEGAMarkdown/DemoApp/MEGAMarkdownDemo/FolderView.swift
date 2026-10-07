import SwiftUI

/// Lists one folder: subfolders first, then files with their size.
struct FolderView: View {
    let folder: URL
    let title: String

    @State private var entries: [TestFileEntry] = []

    var body: some View {
        List(entries) { entry in
            NavigationLink(value: entry) {
                if entry.isFolder {
                    Label(entry.name, systemImage: "folder")
                } else {
                    LabeledContent {
                        Text(entry.byteCount.formatted(.byteCount(style: .file)))
                    } label: {
                        Label(entry.name, systemImage: entry.isImage ? "photo" : "doc.text")
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            entries = TestFileEntry.children(of: folder)
        }
    }
}
