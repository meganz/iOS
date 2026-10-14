import MEGAPDFSearchInterceptor
import PDFKit
import UIKit

@MainActor
final class PDFViewSearchInteractionHandler: NSObject {
    private var findInteraction: UIFindInteraction?
    private weak var pdfView: PDFView?
    private let searchPreferences = PDFViewSearchPreferences()
    private var documentSearcher: PDFDocumentSearcher?
    private var currentSession: PDFViewFindSession?
    private var jumpToSearchResultScrollAdjuster: PDFJumpToSearchResultScrollAdjuster?
    private let makeInterceptor: @MainActor (
        PDFView,
        PDFDocumentSearcher,
        PDFJumpToSearchResultScrollAdjuster?
    ) -> MEGAPDFUITextSearchingFindSessionInterceptor?
    private let reportMissingSearchableView: @MainActor () -> Void
    private let notificationCenter: NotificationCenter

    init(
        notificationCenter: NotificationCenter = .default,
        makeInterceptor: @escaping @MainActor (
            PDFView,
            PDFDocumentSearcher,
            PDFJumpToSearchResultScrollAdjuster?
        ) -> MEGAPDFUITextSearchingFindSessionInterceptor? = {
            MEGAPDFUITextSearchingFindSessionInterceptor(
                pdfView: $0,
                documentSearcher: $1,
                jumpToSearchResultScrollAdjuster: $2
            )
        },
        reportMissingSearchableView: @escaping @MainActor () -> Void = {
            assertionFailure("PDFKit's searchable view is missing")
        }
    ) {
        self.notificationCenter = notificationCenter
        self.makeInterceptor = makeInterceptor
        self.reportMissingSearchableView = reportMissingSearchableView
        super.init()
    }

    func attachToPDFView(_ pdfView: PDFView) {
        guard findInteraction == nil else { return }
        self.pdfView = pdfView
        // One searcher for the view's lifetime, so a search left running by an
        // ended session is still its own to cancel.
        documentSearcher = PDFDocumentSearcher(pdfView: pdfView)
        let interaction = UIFindInteraction(sessionDelegate: self)
        interaction.searchText = ""
        interaction.optionsMenuProvider = { [weak self] in
            self?.searchPreferences.makeMenu(defaultOptions: $0)
        }
        pdfView.addInteraction(interaction)
        findInteraction = interaction
    }

    func presentSearch() {
        // Without PDFKit's searchable view, `findInteraction(_:sessionFor:)`
        // cannot build a session, so PDFKit's own Find takes over.
        if let pdfView, pdfView.window != nil, let documentSearcher,
           makeInterceptor(pdfView, documentSearcher, nil) == nil {
            reportMissingSearchableView()
            pdfView.isFindInteractionEnabled = true
            pdfView.findInteraction.presentFindNavigator(showingReplace: false)
            return
        }
        findInteraction?.presentFindNavigator(showingReplace: false)
    }

    func dismissSearch() {
        findInteraction?.dismissFindNavigator()
        if let pdfView, pdfView.isFindInteractionEnabled {
            pdfView.findInteraction.dismissFindNavigator()
        }
    }
}

extension PDFViewSearchInteractionHandler: UIFindInteractionDelegate {
    func findInteraction(
        _ interaction: UIFindInteraction,
        sessionFor view: UIView
    ) -> UIFindSession? {
        // UIKit needs an attached window to present the Find navigator.
        guard let pdfView, pdfView.window != nil, let documentSearcher else { return nil }
        // Created by the first session, so no keyboard observers run until
        // Find opens, then kept so a keyboard inset it added is still its own
        // to remove. PDFKit may not have created its scroll view yet, so it is
        // looked up on each use.
        let adjuster = jumpToSearchResultScrollAdjuster ?? PDFJumpToSearchResultScrollAdjuster(
            contentScrollView: { [weak pdfView] in pdfView?.contentScrollView },
            notificationCenter: notificationCenter
        )
        guard let interceptor = makeInterceptor(pdfView, documentSearcher, adjuster)
        else { return nil }
        jumpToSearchResultScrollAdjuster = adjuster
        let session = PDFViewFindSession(
            interceptor: interceptor,
            preferences: searchPreferences
        )
        currentSession = session
        return session
    }

    func findInteraction(_ interaction: UIFindInteraction, didEnd findSession: UIFindSession) {
        // Only the latest session's end cancels the search. This guards
        // against possible UIKit misbehaviour that would leave the search out
        // of step with the Find navigator, such as:
        // - reporting the end of an earlier session after the next one has
        //   begun.
        // - calling this twice for one close.
        guard findSession === currentSession else { return }
        documentSearcher?.cancelSearch()
        jumpToSearchResultScrollAdjuster?.clearResultPlacement()
        currentSession = nil
    }
}
