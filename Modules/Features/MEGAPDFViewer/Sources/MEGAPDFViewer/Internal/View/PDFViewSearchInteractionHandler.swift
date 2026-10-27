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
    private let notificationCenter: NotificationCenter
    var onSearchSessionDidBegin: ((UUID) -> Void)?
    var onSearchSessionDidEnd: ((UUID) -> Void)?
    var onSearchResultChanged: ((UUID, UUID, Int) -> Void)?

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        super.init()
    }

    func attachToPDFView(_ pdfView: PDFView) {
        guard findInteraction == nil else { return }
        self.pdfView = pdfView
        // Attach search highlight overlays here (actual code in next MR)
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
        findInteraction?.presentFindNavigator(showingReplace: false)
    }

    func dismissSearch() {
        findInteraction?.dismissFindNavigator()
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
        jumpToSearchResultScrollAdjuster = adjuster
        let session = PDFViewFindSession(
            pdfView: pdfView,
            findInteraction: interaction,
            documentSearcher: documentSearcher,
            preferences: searchPreferences,
            scrollAdjuster: adjuster
        )
        session.onSearchResultChanged = { [weak self, weak session] generationID, resultID in
            guard let session else { return }
            self?.onSearchResultChanged?(session.analyticsID, generationID, resultID)
        }
        currentSession = session
        return session
    }

    func findInteraction(_ interaction: UIFindInteraction, didBegin findSession: UIFindSession) {
        guard let session = findSession as? PDFViewFindSession else { return }
        onSearchSessionDidBegin?(session.analyticsID)
    }

    func findInteraction(_ interaction: UIFindInteraction, didEnd findSession: UIFindSession) {
        // Only the latest session's end cancels the search. This guards
        // against possible UIKit misbehaviour that would leave the search out
        // of step with the Find navigator, such as:
        // - reporting the end of an earlier session after the next one has
        //   begun.
        // - calling this twice for one close.
        guard let endedSession = currentSession, findSession === endedSession else { return }
        onSearchSessionDidEnd?(endedSession.analyticsID)
        endedSession.endSearch()
        jumpToSearchResultScrollAdjuster?.clearResultPlacement()
        currentSession = nil
    }
}
