import MEGAMarkdown
import SwiftUI

/// One `MarkdownPreview` that shows text A or text B. Each button sets the text and a line together,
/// like a host that keeps the saved line of every file.
struct SwitchTextScreen: View {
    private static let textA = paragraphs(word: "Alpha")
    private static let textB = paragraphs(word: "Bravo")

    @State private var markdown = textA
    @State private var restoreLine: Int?
    @State private var topLine = 0
    @State private var reports: [Int] = []

    var body: some View {
        MarkdownPreview(markdown, restoreLine: restoreLine) { position in
            let line = position.topLine
            topLine = line
            reports.append(line)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 4) {
                HStack {
                    Button("Show Alpha") { show(Self.textA, line: nil) }
                    Button("Bravo at line 10000") { show(Self.textB, line: 10_000) }
                }
                .buttonStyle(.bordered)
                Text("Top line \(topLine + 1). Reports: \(reports.suffix(6).map(String.init).joined(separator: ", "))")
                    .font(.caption.monospacedDigit())
                    .accessibilityIdentifier("switch.reports")
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(.bar)
        }
        .navigationTitle("Switch text")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func show(_ text: String, line: Int?) {
        reports = []
        markdown = text
        restoreLine = line
    }

    /// 20,000 paragraphs. Paragraph n is on line 2n, so line 10,000 is paragraph 5,000.
    private static func paragraphs(word: String) -> String {
        (0..<20_000).map { "\(word) paragraph \($0) with some words here." }.joined(separator: "\n\n")
    }
}
