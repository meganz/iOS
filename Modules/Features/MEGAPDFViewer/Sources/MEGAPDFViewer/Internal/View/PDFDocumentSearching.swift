import MEGASwift

@MainActor
protocol PDFDocumentSearching: AnyObject {
    /// Cancels any earlier search, then yields each match in document order
    /// and finishes when the search ends.
    /// - Cancelling the task that iterates the matches cancels the search.
    func matches(for query: String, compareOptions: String.CompareOptions) -> AnyAsyncSequence<PDFSearchMatch>
}
