@testable import MEGAPDFViewer
import PDFKit
import Testing
import UIKit

@Suite(.serialized)
@MainActor
struct PDFDocumentSearcherTests {
    @Test(arguments: ["ALPHA", "alpha beta"])
    func ownQueryMatches_areAllReported(query: String) async throws {
        let fixture = try await SearchFixture(pages: ["alpha\nbeta alpha beta"])
        let expectedCount = try #require(
            fixture.pdfView.document?.findString(query, withOptions: .caseInsensitive).count
        )
        let recorder = SearchRecorder()

        recorder.search(query, compareOptions: .caseInsensitive, with: fixture.searcher)
        try await recorder.waitUntilFinished()

        #expect(recorder.matches.count == expectedCount)
    }

    @Test func matchesOnLaterPages_areReportedInDocumentOrder() async throws {
        let fixture = try await SearchFixture(pages: [
            "first page words here",
            "second page alpha one",
            "alpha starts third page"
        ])
        let recorder = SearchRecorder()

        recorder.search("alpha", with: fixture.searcher)
        try await recorder.waitUntilFinished()

        #expect(recorder.matches.map(\.pageIndex) == [1, 2])
        #expect(recorder.matches.map { $0.selection.string } == ["alpha", "alpha"])
    }

    @Test func staleMatchOfEarlierQuery_isNotReported() async throws {
        let fixture = try await SearchFixture(pages: ["alpha beta"])
        let staleMatch = try #require(
            fixture.pdfView.document?.findString("alpha", withOptions: []).first
        )
        let recorder = SearchRecorder()

        recorder.search("beta", with: fixture.searcher)
        fixture.searcher.didMatchString(staleMatch)
        try await recorder.waitUntilFinished()

        #expect(recorder.matches.map { $0.selection.string } == ["beta"])
    }

    @Test func newQuery_reportsOnlyItsOwnMatches() async throws {
        let fixture = try await SearchFixture(pages: ["alpha beta", "beta alpha beta"])
        let first = SearchRecorder()
        let second = SearchRecorder()

        first.search("alpha", with: fixture.searcher)
        second.search("beta", with: fixture.searcher)
        try await second.waitUntilFinished()
        try await Task.sleep(for: .milliseconds(200))

        #expect(second.matches.map { $0.selection.string } == ["beta", "beta", "beta"])
        #expect(first.matches.allSatisfy { $0.selection.string == "alpha" })
    }

    @Test func releasedSearcher_cancelsItsSearch() async throws {
        let fixture = try await SearchFixture(pages: ["alpha on a page"])
        let recorder = SearchRecorder()
        do {
            let searcher = PDFDocumentSearcher(pdfView: fixture.pdfView)
            recorder.search("alpha", with: searcher)
            #expect(fixture.pdfView.document?.isFinding == true)
        }

        #expect(fixture.pdfView.document?.isFinding == false)
    }

    @Test func cancelSearch_afterDocumentReplaced_cancelsSearchedDocument() async throws {
        let fixture = try await SearchFixture(pages: ["alpha on a page"])
        let searchedDocument = try #require(fixture.pdfView.document)
        let recorder = SearchRecorder()
        recorder.search("alpha", with: fixture.searcher)
        try #require(searchedDocument.isFinding)
        fixture.pdfView.document = PDFDocument()

        fixture.searcher.cancelSearch()

        #expect(searchedDocument.isFinding == false)
    }

    @Test func cancelledIteration_cancelsTheSearch() async throws {
        let fixture = try await SearchFixture(pages: ["alpha on a page"])
        let document = try #require(fixture.pdfView.document)
        let recorder = SearchRecorder()
        recorder.search("alpha", with: fixture.searcher)
        try #require(document.isFinding)

        recorder.cancel()
        for _ in 0..<50 where document.isFinding {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(document.isFinding == false)
    }

    @Test func lateCancellationOfEarlierIteration_leavesNextSearchRunning() async throws {
        let fixture = try await SearchFixture(pages: ["alpha on a page", "alpha again"])
        let first = SearchRecorder()
        let second = SearchRecorder()
        first.search("alpha", with: fixture.searcher)
        first.cancel()

        second.search("alpha", with: fixture.searcher)
        try await second.waitUntilFinished()

        #expect(second.matches.count == 2)
    }

    @Test func search_leavesCurrentSelectionUntouched() async throws {
        let fixture = try await SearchFixture(pages: ["alpha on a page", "alpha again"])
        let selectionChanges = SelectionChangeCounter()
        let observer = NotificationCenter.default.addObserver(
            forName: .PDFViewSelectionChanged,
            object: fixture.pdfView,
            queue: nil
        ) { _ in selectionChanges.increment() }
        defer { NotificationCenter.default.removeObserver(observer) }
        let recorder = SearchRecorder()

        recorder.search("alpha", with: fixture.searcher)
        try await recorder.waitUntilFinished()

        #expect(recorder.matches.count == 2)
        #expect(selectionChanges.count == 0)
        #expect(fixture.pdfView.currentSelection == nil)
    }
}

/// Records one search's matches and its end.
@MainActor
final class SearchRecorder {
    private(set) var matches: [PDFSearchMatch] = []
    private(set) var didFinish = false
    private var task: Task<Void, Never>?

    func search(
        _ query: String,
        compareOptions: String.CompareOptions = .caseInsensitive,
        with searcher: any PDFDocumentSearching
    ) {
        let sequence = searcher.matches(for: query, compareOptions: compareOptions)
        task = Task { [weak self] in
            for await match in sequence {
                self?.matches.append(match)
            }
            self?.didFinish = true
        }
    }

    func cancel() {
        task?.cancel()
    }

    func waitUntilFinished() async throws {
        for _ in 0..<100 where !didFinish {
            try await Task.sleep(for: .milliseconds(50))
        }
        try #require(didFinish)
    }
}

final class SelectionChangeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    var count: Int { lock.withLock { value } }

    func increment() {
        lock.withLock { value += 1 }
    }
}
