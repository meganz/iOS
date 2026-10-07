import SwiftUI

/// Opens every test file in turn, the same way a person would, and saves screenshots of it.
struct CaptureView: View {
    let config: CaptureConfig

    @State private var entry: TestFileEntry?
    @State private var isDone = false

    var body: some View {
        NavigationStack {
            if let entry {
                FileScreen(entry: entry, usesSavedLine: false)
                    // A new file must get a new screen, with its own options and load.
                    .id(entry)
            } else {
                Text(isDone ? "Capture done" : "Capture starting")
            }
        }
        .task {
            // The capture uses the newest files of the repo.
            await TestFilesSync().run()
            await CaptureRunner(config: config).run { entry = $0 }
            entry = nil
            isDone = true
        }
    }
}
