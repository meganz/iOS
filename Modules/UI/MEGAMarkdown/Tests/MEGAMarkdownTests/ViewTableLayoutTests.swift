@testable import MEGAMarkdown
import SwiftUI
import Testing
import UIKit

/// Table rows must grow with their tallest cell. Nothing may be clipped.
/// Uses a real hosting view, because ImageRenderer does not lay out a ScrollView like a live view does.
@MainActor
@Suite struct ViewTableLayoutTests {
    private struct HeightKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }

    /// Proposes a fixed height to its child, but lets the child pick its own size.
    /// A lazy stack can re-propose a cached height like this. The table must still use its real height.
    private struct ProposeHeight: Layout {
        let height: CGFloat?

        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            subviews.first?.sizeThatFits(ProposedViewSize(width: proposal.width, height: height)) ?? .zero
        }

        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(width: bounds.width, height: height))
        }
    }

    @MainActor private final class Box {
        var height: CGFloat = 0
    }

    private func table(lastName: String) -> MarkdownTable {
        MarkdownTable(
            columns: [.init(alignment: .none), .init(alignment: .none)],
            header: ["Name", "Size"],
            rows: [["photo.jpg", "2 MB"], [AttributedString(lastName), "10 MB"]]
        )
    }

    /// Height of the table inside a lazy stack in a scroll view, once two reads 50 ms apart agree.
    private func heightInReader(_ table: MarkdownTable, proposedHeight: CGFloat? = nil) async throws -> CGFloat {
        let box = Box()
        let root = ScrollView {
            LazyVStack(alignment: .leading) {
                ProposeHeight(height: proposedHeight) {
                    TableBlockView(table: table)
                        .background(GeometryReader { Color.clear.preference(key: HeightKey.self, value: $0.size.height) })
                }
            }
            .padding(16)
        }
        .onPreferenceChange(HeightKey.self) { value in
            MainActor.assumeIsolated { box.height = value }
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 800))
        window.rootViewController = UIHostingController(rootView: root)
        window.makeKeyAndVisible()
        var lastHeight: CGFloat = 0
        // 200 polls, about 10 s. It counts polls, not clock time:
        // on a busy machine another test can hold the main actor for seconds.
        for _ in 0..<200 {
            window.layoutIfNeeded()
            if box.height > 0, box.height == lastHeight {
                return box.height
            }
            lastHeight = box.height
            try await Task.sleep(for: .milliseconds(50))
        }
        throw CancellationError()
    }

    @Test(arguments: [60.0, 150.0, 400.0])
    func tableIgnoresAProposedHeight(proposedHeight: Double) async throws {
        let long = table(lastName: String(repeating: "a very long file name ", count: 6))
        let natural = try await heightInReader(long)
        let proposed = try await heightInReader(long, proposedHeight: proposedHeight)
        #expect(natural > 0)
        #expect(abs(proposed - natural) < 1, "natural \(natural) with proposal \(proposedHeight): \(proposed)")
    }

    @Test func longCellMakesItsRowTaller() async throws {
        let short = try await heightInReader(table(lastName: "a.md"))
        let long = try await heightInReader(table(lastName: String(repeating: "a very long file name ", count: 6)))
        #expect(short > 0)
        // The long cell wraps to many lines at 140pt, so the table must be clearly taller.
        #expect(long > short + 60, "short \(short) long \(long)")
    }
}
