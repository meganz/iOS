import MEGAMarkdown
import SwiftUI

/// Opens one generated Markdown file in `MarkdownPreview`. The UI tests choose the file size
/// with the launch argument `-varied-mb <megabytes>`.
@main
struct BenchmarkHostApp: App {
    var body: some Scene {
        WindowGroup {
            HostScreen(megabytes: Self.launchMegabytes)
        }
    }

    private static var launchMegabytes: Int {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-varied-mb"), index + 1 < arguments.count else { return 2 }
        return Int(arguments[index + 1]) ?? 2
    }
}

struct HostScreen: View {
    let megabytes: Int
    @State private var text: String?

    var body: some View {
        Group {
            if let text {
                MarkdownPreview(text)
            } else {
                ProgressView()
            }
        }
        .task {
            text = await VariedSections.cachedText(megabytes: megabytes)
        }
    }
}
