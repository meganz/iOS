import SwiftUI

/// The synced test files, with the Sync button.
struct TestFilesScreen: View {
    @State private var sync = TestFilesSync()

    var body: some View {
        Group {
            if let root = TestFileEntry.root {
                FolderView(folder: root, title: "Test files")
                    // A sync can add or remove files, so the list reads the folder again.
                    .id(sync.generation)
            } else {
                ContentUnavailableView(
                    "No test files",
                    systemImage: "folder.badge.questionmark",
                    description: Text("Tap Sync to download them from github.com/\(TestFilesSync.repository).")
                )
            }
        }
        .navigationTitle("Test files")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            syncStatus
        }
        .toolbar {
            Button("Sync", systemImage: "arrow.triangle.2.circlepath") {
                Task { await sync.run() }
            }
            .disabled(sync.isSyncing)
        }
    }

    @ViewBuilder private var syncStatus: some View {
        switch sync.state {
        case .idle:
            EmptyView()
        case .syncing(let done, let total):
            Text(total == 0 ? "Reading the file list" : "Syncing \(done) of \(total) files")
                .statusStyle()
        case .failed(let message):
            Text("Sync failed: \(message)")
                .foregroundStyle(.red)
                .statusStyle()
        }
    }
}

private extension View {
    func statusStyle() -> some View {
        font(.caption)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(.bar)
    }
}
