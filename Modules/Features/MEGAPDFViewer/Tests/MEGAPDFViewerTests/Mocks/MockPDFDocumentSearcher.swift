@testable import MEGAPDFViewer
import MEGASwift
import PDFKit

@MainActor
final class MockPDFDocumentSearcher: PDFDocumentSearching {
    struct Search: Equatable {
        let query: String
        let compareOptions: String.CompareOptions
    }

    private(set) var searches: [Search] = []
    private(set) var cancelCount = 0
    private var continuation: AsyncStream<PDFSearchMatch>.Continuation?

    func matches(for query: String, compareOptions: String.CompareOptions) -> AnyAsyncSequence<PDFSearchMatch> {
        searches.append(Search(query: query, compareOptions: compareOptions))
        continuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(of: PDFSearchMatch.self)
        continuation.onTermination = { [weak self] termination in
            guard case .cancelled = termination else { return }
            Task { @MainActor in self?.cancelCount += 1 }
        }
        self.continuation = continuation
        return AnyAsyncSequence(stream)
    }

    /// Reports `match` to the latest search, as PDFKit would, and lets its
    /// consumer run.
    func report(_ match: PDFSearchMatch) async {
        continuation?.yield(match)
        await settle()
    }

    /// Ends the latest search, as PDFKit would, and lets its consumer run.
    func finish() async {
        continuation?.finish()
        await settle()
    }
}
