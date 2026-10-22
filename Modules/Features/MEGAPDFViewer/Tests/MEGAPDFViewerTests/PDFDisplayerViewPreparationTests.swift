@testable import MEGAPDFViewer
import PDFKit
import SwiftUI
import Testing
import UIKit

@MainActor
@Observable
private final class DisplayerHost {
    var currentPage = 0
    var preparedCount = 0
    /// Each write to `currentPage`, with `preparedCount` at the time.
    var currentPageWrites: [(page: Int, preparedCount: Int)] = []
}

private struct HostedPreparingDisplayerView: View {
    let document: PDFDocument
    let initialPageIndex: Int?
    @Bindable var host: DisplayerHost

    var body: some View {
        PDFDisplayerView(
            document: document,
            initialPageIndex: initialPageIndex,
            onDidFinishPreparingForDisplayAndInteraction: { host.preparedCount += 1 },
            interaction: .init(
                scroll: .init(
                    currentPage: Binding(
                        get: { host.currentPage },
                        set: {
                            host.currentPageWrites.append((page: $0, preparedCount: host.preparedCount))
                            host.currentPage = $0
                        }
                    ),
                    isProgrammaticallyScrollingToCurrentPage: .constant(false),
                    onIsScrolledToTopChange: { _ in }
                ),
                search: .init(request: .constant(nil)),
                tap: .init(onDocumentTapped: {}, onLinkTapped: { _ in })
            )
        )
    }
}

@MainActor
struct PDFDisplayerViewPreparationTests {
    @Test(arguments: [nil, 12] as [Int?])
    func preparationIsReportedOnce(initialPageIndex: Int?) async throws {
        let (window, host) = try makeSUT(initialPageIndex: initialPageIndex)
        defer { window.isHidden = true }

        try await waitUntil(timeout: .seconds(3)) { host.preparedCount > 0 }
        try await Task.sleep(for: .milliseconds(300))

        #expect(host.preparedCount == 1)
    }

    @Test
    func currentPageIsReportedOnlyOncePreparationFinishes() async throws {
        let (window, host) = try makeSUT(initialPageIndex: 12)
        defer { window.isHidden = true }

        try await waitUntil(timeout: .seconds(3)) { host.preparedCount > 0 && host.currentPage == 12 }

        #expect(host.currentPage == 12)
        #expect(!host.currentPageWrites.isEmpty)
        #expect(host.currentPageWrites.allSatisfy { $0.preparedCount > 0 })
    }

    private func waitUntil(timeout: Duration, _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    private func makeSUT(initialPageIndex: Int?) throws -> (UIWindow, DisplayerHost) {
        let frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        let data = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)).pdfData { context in
            for _ in 0..<20 { context.beginPage() }
        }
        let host = DisplayerHost()
        let window = UIWindow(frame: frame)
        window.rootViewController = UIHostingController(
            rootView: HostedPreparingDisplayerView(
                document: try #require(PDFDocument(data: data)),
                initialPageIndex: initialPageIndex,
                host: host
            )
        )
        window.makeKeyAndVisible()
        return (window, host)
    }
}
