import MEGAPDFSearchInterceptor
import PDFKit
import UIKit

/// Searches the text layer of the document shown in `pdfView`, and reports
/// each match as the range PDFKit's searchable view would report for it.
@MainActor
final class PDFDocumentSearcher: NSObject, PDFDocumentSearching {
    private weak var pdfView: PDFView?
    private weak var textInput: (any UITextInput)?
    private weak var searchedDocument: PDFDocument?
    private var query = ""
    private var compareOptions: String.CompareOptions = []
    private var onMatch: ((UITextRange) -> Void)?
    private var onFinish: (() -> Void)?

    init(pdfView: PDFView) {
        self.pdfView = pdfView
    }

    isolated deinit {
        // A running search would otherwise go on with no delegate.
        if onFinish != nil {
            searchedDocument?.cancelFindString()
        }
    }

    func search(
        for string: String,
        options: UITextSearchOptions,
        in textInput: any UITextInput,
        onMatch: @escaping (UITextRange) -> Void,
        onFinish: @escaping () -> Void
    ) {
        cancelSearch()
        guard string.count >= 4, let document = pdfView?.document else {
            onFinish()
            return
        }
        // PDFKit's searchable view waits for PDFKit's image text recognition
        // of every page, including the recognition started by an earlier
        // query, so a query typed while that runs reports nothing until it
        // ends. `-[PDFDocument beginFindString:withOptions:]` searches only the
        // text layer and never waits for it.
        self.textInput = textInput
        query = string
        compareOptions = options.stringCompareOptions
        self.onMatch = onMatch
        self.onFinish = onFinish
        searchedDocument = document
        document.delegate = self
        document.beginFindString(string, withOptions: options.stringCompareOptions)
    }

    /// Stops the current search without calling its `onFinish`.
    func cancelSearch() {
        // `cancelFindString` reports the end of the cancelled search
        // synchronously, so the callbacks are dropped first.
        onMatch = nil
        onFinish = nil
        guard let searchedDocument, searchedDocument.delegate === self else { return }
        searchedDocument.cancelFindString()
    }

    private func textRange(for selection: PDFSelection) -> UITextRange? {
        // The range is read back from the searchable view's
        // `selectedTextRange` after selecting the match, instead of being
        // built from the `PDFSelection` character indices:
        // - On iOS 18, the `UITextInput` offsets of PDFKit's searchable view
        //   drift from those indices, by about one per line.
        // - On iOS 26 and later, `position(from:offset:)` resolves the offset
        //   of a page's first character to the end of the previous page, so
        //   a range built for a match that starts a page breaks navigation
        //   between matches.
        // The previous selection is restored afterwards.
        guard let pdfView, let textInput else { return nil }
        let previousSelection = pdfView.currentSelection
        pdfView.currentSelection = selection
        let range = textInput.selectedTextRange
        pdfView.currentSelection = previousSelection
        return range
    }
}

// MARK: - PDFDocumentDelegate

extension PDFDocumentSearcher: @preconcurrency PDFDocumentDelegate {
    func didMatchString(_ instance: PDFSelection) {
        // PDFKit can keep reporting matches after the search's end, which
        // already dropped `onMatch`. Its callbacks do not say which search they
        // belong to, so a match of a cancelled search is also dropped by its
        // text, in case PDFKit reports one after the next search begins.
        guard let onMatch,
              instance.string?.compare(query, options: compareOptions) == .orderedSame,
              let range = textRange(for: instance)
        else { return }
        onMatch(range)
    }

    func documentDidEndDocumentFind(_ notification: Notification) {
        let onFinish = onFinish
        onMatch = nil
        self.onFinish = nil
        onFinish?()
    }
}
