import Foundation
@testable import MEGAMarkdown
import Observation
import Testing

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PreviewModelTests {
    private static let smallChunks = PreviewParseLimits(targetChunkBytes: 4_096)

    private static func paragraphs(_ count: Int, word: String = "Paragraph") -> String {
        (0..<count).map { "\(word) \($0) with some words." }.joined(separator: "\n\n")
    }

    /// The rows one parse gives, for comparing with the model's store.
    private static func rows(_ markdown: String, limits: PreviewParseLimits = smallChunks) -> [PreviewRow] {
        var rows: [PreviewRow] = []
        _ = PreviewPipeline.parse(MarkdownParseRequest(markdown: markdown), limits: limits) { rows += $0.rows }
        return rows
    }

    private static func firstBatchRowCount(_ markdown: String) -> Int {
        var counts: [Int] = []
        _ = PreviewPipeline.parse(MarkdownParseRequest(markdown: markdown), limits: smallChunks) { counts.append($0.rows.count) }
        return counts.first ?? 0
    }

    private static func storeRows(_ model: PreviewModel) -> [PreviewRow] {
        (0..<model.store.count).map { model.store[$0] }
    }

    private struct TimedOut: Error {}

    private static func waitUntil(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(20)
        while !condition() {
            guard ContinuousClock.now < deadline else { throw TimedOut() }
            try await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test func loadPublishesTheRowsAndCompletes() async {
        let model = PreviewModel()
        #expect(model.phase == .loading)
        let markdown = Self.paragraphs(1_000)
        let baseURL = URL(string: "https://mega.io/docs/")
        await model.load(MarkdownParseRequest(markdown: markdown, baseURL: baseURL), limits: Self.smallChunks)
        #expect(model.phase == .rows)
        #expect(model.generation == 1)
        #expect(model.isComplete)
        #expect(model.rowCount == 1_000)
        #expect(model.store.count == 1_000)
        #expect(Self.storeRows(model) == Self.rows(markdown))
        #expect(model.baseURL == baseURL)
    }

    @Test func newTextIsANewGeneration() async {
        let model = PreviewModel()
        await model.load(MarkdownParseRequest(markdown: Self.paragraphs(10)))
        await model.load(MarkdownParseRequest(markdown: Self.paragraphs(3, word: "Other")))
        #expect(model.generation == 2)
        #expect(model.rowCount == 3)
        #expect(Self.storeRows(model) == Self.rows(Self.paragraphs(3, word: "Other")))
    }

    /// `.task` runs again when the view appears again. The same complete text keeps its rows and generation.
    @Test func sameCompleteTextDoesNotLoadAgain() async {
        let model = PreviewModel()
        let request = MarkdownParseRequest(markdown: Self.paragraphs(10))
        await model.load(request)
        let store = model.store
        await model.load(request)
        #expect(model.generation == 1)
        #expect(model.store === store)
        #expect(model.rowCount == 10)
    }

    /// "é" and "e" + U+0301 are equal Strings but different bytes, and only the first text has a link.
    /// The second text is a new load, also for `.task(id:)`, which compares requests the same way.
    @Test func canonicallyEqualTextWithOtherBytesLoadsAgain() async {
        let model = PreviewModel()
        // The preview splits every paragraph, so the paragraph is a text piece row.
        let hasLink = { () -> Bool in
            guard model.store.count > 0, case .textPiece(let text, _, _) = model.store[0].content else { return false }
            return text.runs.contains { $0.link >= 0 }
        }
        await model.load(MarkdownParseRequest(markdown: "[x][\u{E9}]\n\n[\u{E9}]: /destination"))
        #expect(hasLink())
        await model.load(MarkdownParseRequest(markdown: "[x][\u{E9}]\n\n[e\u{301}]: /destination"))
        #expect(model.generation == 2)
        #expect(!hasLink())
    }

    @Test func emptyTextHasNoRowsAndCompletes() async {
        let model = PreviewModel()
        await model.load(MarkdownParseRequest(markdown: ""))
        #expect(model.phase == .rows)
        #expect(model.generation == 1)
        #expect(model.rowCount == 0)
        #expect(model.isComplete)
    }

    @Test func textOverTheLimitIsTooLarge() async {
        let model = PreviewModel()
        await model.load(MarkdownParseRequest(markdown: Self.paragraphs(10)))
        var limits = PreviewParseLimits()
        limits.sizeLimitBytes = 10
        await model.load(MarkdownParseRequest(markdown: "12345678901"), limits: limits)
        #expect(model.phase == .tooLarge)
        #expect(model.generation == 2)
        #expect(model.rowCount == 0)
        #expect(model.store.isEmpty)
    }

    /// A slow load of a big text goes on while a new text loads. Its later batches must not reach the new rows.
    @Test func batchesOfAnOlderLoadAreDropped() async throws {
        let model = PreviewModel()
        let big = Self.paragraphs(100_000)
        let old = Task { await model.load(MarkdownParseRequest(markdown: big), limits: Self.smallChunks) }
        try await Self.waitUntil { model.rowCount > 0 }
        let newText = Self.paragraphs(5, word: "New")
        await model.load(MarkdownParseRequest(markdown: newText), limits: Self.smallChunks)
        await old.value
        #expect(model.generation == 2)
        #expect(model.isComplete)
        #expect(Self.storeRows(model) == Self.rows(newText))
    }

    /// A cancelled load keeps the rows that arrived. They are the start of the full rows.
    @Test func cancelKeepsTheRowsThatArrived() async throws {
        let model = PreviewModel()
        let big = Self.paragraphs(100_000)
        let load = Task { await model.load(MarkdownParseRequest(markdown: big), limits: Self.smallChunks) }
        // Cancel inside the first row update. A timed check can come after the whole parse on a busy machine.
        withObservationTracking { _ = model.rowCount } onChange: { load.cancel() }
        await load.value
        let kept = Self.storeRows(model)
        let firstBatch = Self.firstBatchRowCount(big)
        #expect(!model.isComplete)
        #expect(model.phase == .rows)
        #expect(model.rowCount == kept.count)
        #expect(kept.count == firstBatch)
        #expect(firstBatch > 0 && firstBatch < 100_000)
        #expect(kept == Array(Self.rows(big).prefix(kept.count)))
    }

    /// A load that continues a cancelled load of the same text keeps the generation and ends with the full rows.
    @Test func loadAfterACancelKeepsTheGenerationAndFinishesTheRows() async throws {
        let model = PreviewModel()
        let request = MarkdownParseRequest(markdown: Self.paragraphs(20_000))
        let load = Task { await model.load(request, limits: Self.smallChunks) }
        withObservationTracking { _ = model.rowCount } onChange: { load.cancel() }
        await load.value
        #expect(!model.isComplete)
        let generation = model.generation
        await model.load(request, limits: Self.smallChunks)
        #expect(model.generation == generation)
        #expect(model.isComplete)
        #expect(Self.storeRows(model) == Self.rows(request.markdown))
    }
}
