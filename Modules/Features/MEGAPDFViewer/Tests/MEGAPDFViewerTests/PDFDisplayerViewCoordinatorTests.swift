@testable import MEGAPDFViewer
import PDFKit
import SwiftUI
import Testing
import UIKit

@MainActor
private final class SearchRequestState {
    var request: PDFSearchRequest?
}

@MainActor
@Observable
private final class ObservableSearchRequest {
    var request: PDFSearchRequest?
}

private struct HostedPDFDisplayerView: View {
    let document: PDFDocument
    @Bindable var searchRequest: ObservableSearchRequest

    var body: some View {
        PDFDisplayerView(
            document: document,
            initialPageIndex: nil,
            onDidFinishPreparingForDisplayAndInteraction: {},
            interaction: .init(
                scroll: .init(
                    currentPage: .constant(0),
                    isProgrammaticallyScrollingToCurrentPage: .constant(false),
                    onIsScrolledToTopChange: { _ in }
                ),
                search: .init(request: $searchRequest.request),
                tap: .init(onDocumentTapped: {}, onLinkTapped: { _ in })
            )
        )
    }
}

extension FindNavigatorPresentationTests {
    @MainActor
    struct PDFDisplayerViewCoordinatorTests {
        @Test func presentRequest_showsFindAndClearsRequest() async throws {
            let (window, pdfView, state, coordinator) = try await makeSUT()
            defer {
                pdfView.dismissSearch()
                window.isHidden = true
            }
            state.request = .present

            coordinator.sendSearchRequest(to: pdfView)

            let interaction = try #require(findInteraction(of: pdfView))
            for _ in 0..<20 where !interaction.isFindNavigatorVisible {
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(interaction.isFindNavigatorVisible)
            #expect(state.request == nil)
        }

        @Test func requestReplacedBeforeSending_sendsLatestOnly() async throws {
            let (window, pdfView, state, coordinator) = try await makeSUT()
            defer { window.isHidden = true }
            state.request = .present

            coordinator.sendSearchRequest(to: pdfView)
            state.request = .dismiss
            try await Task.sleep(for: .milliseconds(500))

            let interaction = try #require(findInteraction(of: pdfView))
            #expect(!interaction.isFindNavigatorVisible)
            #expect(state.request == nil)
        }

        @Test func dismissRequest_closesFind() async throws {
            let (window, pdfView, state, coordinator) = try await makeSUT()
            defer { window.isHidden = true }
            let interaction = try #require(findInteraction(of: pdfView))
            pdfView.presentSearch()
            for _ in 0..<20 where !interaction.isFindNavigatorVisible {
                try await Task.sleep(for: .milliseconds(100))
            }
            state.request = .dismiss

            coordinator.sendSearchRequest(to: pdfView)

            for _ in 0..<20 where interaction.isFindNavigatorVisible {
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(!interaction.isFindNavigatorVisible)
            #expect(state.request == nil)
        }

        @Test func requestSetOnHostedView_isSentThroughUpdate() async throws {
            let frame = CGRect(x: 0, y: 0, width: 400, height: 700)
            let data = UIGraphicsPDFRenderer(bounds: frame).pdfData { context in
                context.beginPage()
                "test tested".draw(at: CGPoint(x: 48, y: 48))
            }
            let searchRequest = ObservableSearchRequest()
            let window = UIWindow(frame: frame)
            window.rootViewController = UIHostingController(
                rootView: HostedPDFDisplayerView(
                    document: try #require(PDFDocument(data: data)),
                    searchRequest: searchRequest
                )
            )
            window.makeKeyAndVisible()
            defer { window.isHidden = true }
            try await Task.sleep(for: .milliseconds(300))
            let pdfView = try #require(megaPDFView(in: window))
            let interaction = try #require(findInteraction(of: pdfView))
            defer { pdfView.dismissSearch() }

            searchRequest.request = .present

            for _ in 0..<20 where !interaction.isFindNavigatorVisible {
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(interaction.isFindNavigatorVisible)
            #expect(searchRequest.request == nil)
        }

        private func megaPDFView(in view: UIView) -> MEGAPDFView? {
            if let pdfView = view as? MEGAPDFView { return pdfView }
            return view.subviews.lazy.compactMap { megaPDFView(in: $0) }.first
        }

        private func makeSUT() async throws -> (UIWindow, MEGAPDFView, SearchRequestState, PDFDisplayerView.Coordinator) {
            let frame = CGRect(x: 0, y: 0, width: 400, height: 700)
            let window = UIWindow(frame: frame)
            let root = UIViewController()
            window.rootViewController = root
            window.makeKeyAndVisible()
            let pdfView = MEGAPDFView(frame: frame)
            root.view.addSubview(pdfView)
            let data = UIGraphicsPDFRenderer(bounds: frame).pdfData { context in
                context.beginPage()
                "test tested".draw(at: CGPoint(x: 48, y: 48))
            }
            let document = try #require(PDFDocument(data: data))
            try await pdfView.configureAndAwaitDisplayPreparation(document: document)
            let state = SearchRequestState()
            let parent = PDFDisplayerView(
                document: document,
                initialPageIndex: nil,
                onDidFinishPreparingForDisplayAndInteraction: {},
                interaction: .init(
                    scroll: .init(
                        currentPage: .constant(0),
                        isProgrammaticallyScrollingToCurrentPage: .constant(false),
                        onIsScrolledToTopChange: { _ in }
                    ),
                    search: .init(request: Binding(get: { state.request }, set: { state.request = $0 })),
                    tap: .init(onDocumentTapped: {}, onLinkTapped: { _ in })
                )
            )
            return (window, pdfView, state, PDFDisplayerView.Coordinator(parent: parent))
        }

        private func findInteraction(of pdfView: PDFView) -> UIFindInteraction? {
            pdfView.interactions.compactMap { $0 as? UIFindInteraction }.first
        }
    }
}
