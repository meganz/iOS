@testable import MEGAMarkdown
import SwiftUI
import Testing
import UIKit

/// A long code line must scroll sideways, and the scroll area must reach the box edge.
/// Uses a real window, because only a live `UIScrollView` has a content size.
@MainActor
@Suite(.serialized) struct ViewCodeBlockLayoutTests {
    private static let blockWidth: CGFloat = 300

    private func horizontalScrollViews(in view: UIView) -> [UIScrollView] {
        var found: [UIScrollView] = []
        if let scrollView = view as? UIScrollView {
            found.append(scrollView)
        }
        for child in view.subviews {
            found += horizontalScrollViews(in: child)
        }
        return found
    }

    /// Hosts one code block at a fixed width and returns its scroll view once it is laid out.
    private func codeScrollView(code: String) async throws -> UIScrollView {
        let root = CodeBlockView(language: "json", code: code)
            .frame(width: Self.blockWidth)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        window.rootViewController = UIHostingController(rootView: root)
        window.makeKeyAndVisible()
        let deadline = ContinuousClock.now + .seconds(10)
        while ContinuousClock.now < deadline {
            window.layoutIfNeeded()
            if let scrollView = horizontalScrollViews(in: window).first(where: { $0.contentSize.width > 0 }) {
                return scrollView
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        throw CancellationError()
    }

    @Test func longLineScrollsSideways() async throws {
        let scrollView = try await codeScrollView(code: String(repeating: "{ \"key\": \"value\" } ", count: 10))
        #expect(scrollView.contentSize.width > scrollView.bounds.width, "content \(scrollView.contentSize.width) bounds \(scrollView.bounds.width)")
    }

    @Test func scrollAreaReachesTheBoxEdge() async throws {
        let scrollView = try await codeScrollView(code: String(repeating: "x", count: 200))
        // The side padding sits inside the scroll content, so the visible area is the full block width.
        #expect(abs(scrollView.bounds.width - Self.blockWidth) < 1, "bounds \(scrollView.bounds.width)")
    }

    @Test func shortLineDoesNotScroll() async throws {
        let scrollView = try await codeScrollView(code: "let a = 1")
        #expect(scrollView.contentSize.width <= scrollView.bounds.width + 1)
    }
}
