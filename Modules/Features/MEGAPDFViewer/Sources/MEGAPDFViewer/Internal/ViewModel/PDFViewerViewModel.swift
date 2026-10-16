import Foundation
import MEGADomain
import MEGAL10n
import Observation
@preconcurrency import PDFKit

@Observable
@MainActor
final class PDFViewerViewModel {
    struct Dependency {
        let pdfDocumentSource: PDFViewerDocumentSource
        let documentURLUseCase: any PDFDocumentURLUseCaseProtocol
        let documentLoadingUseCase: any PDFViewerDocumentLoadingUseCaseProtocol
        let lastPageUseCase: any PDFViewerLastPageUseCaseProtocol
        let leftOffItemRecordUseCase: any LeftOffItemRecordUseCaseProtocol
        let node: NodeEntity?
        let nearestOutlineItemUseCase: any PDFNearestOutlineItemUseCaseProtocol
        let fileName: String
        var actionContext: PDFViewerActionContext = .init()
        var hasMoreAction = false
        var hasDownloadAction = false
        var trackingUseCase: any PDFViewerTrackingUseCaseProtocol = PDFViewerTrackingUseCase()
    }

    struct TrailingActionUseCase {
        func action(
            source: PDFViewerDocumentSource,
            context: PDFViewerActionContext,
            hasMoreAction: Bool,
            hasDownloadAction: Bool
        ) -> PDFViewerTrailingAction {
            if context.hasNode {
                return hasMoreAction ? .more : .none
            }
            guard !context.isLink, !context.isChat,
                  case .local = source, hasDownloadAction else { return .none }
            return .download
        }
    }

    var trailingAction: PDFViewerTrailingAction {
        TrailingActionUseCase().action(
            source: dependency.pdfDocumentSource,
            context: dependency.actionContext,
            hasMoreAction: dependency.hasMoreAction,
            hasDownloadAction: dependency.hasDownloadAction
        )
    }

    enum ViewState: Equatable {
        struct DocumentLockedState: Equatable {
            let document: PDFDocument
            let localDocumentURL: URL
            var password = ""
            var showInvalidPasswordError = false
            var isSubmissionEnabled = true
            var isPasswordEntryPresented = true
            var passwordRejectionCount = 0
        }

        struct ReadyState: Equatable {
            struct PagingState: Equatable {
                var currentPageIndex: Int
                var pageCount: Int
            }

            struct OutlineState: Equatable {
                struct OutlineLoadingState: Equatable {
                    let shouldLoadOutline: Bool
                    let outlineDocumentURL: URL?
                    var isLoadingOutline = false

                    init(_ state: PDFViewerDocumentLoadingState.ReadyState.OutlineLoadingState) {
                        shouldLoadOutline = state.shouldLoadOutline
                        outlineDocumentURL = state.outlineDocumentURL
                    }
                }

                var outlineItems: PDFOutlineItems
                var outlineLoadingState: OutlineLoadingState?
                var isShowingOutline: Bool
                var activeOutlineItemID: String?

                init(outlineLoadingState: OutlineLoadingState) {
                    self.init(
                        outlineItems: PDFOutlineItems(inOutlineOrder: [], inPageOrder: []),
                        outlineLoadingState: outlineLoadingState,
                        isShowingOutline: false,
                        activeOutlineItemID: nil
                    )
                }

                init(
                    outlineItems: PDFOutlineItems,
                    outlineLoadingState: OutlineLoadingState?,
                    isShowingOutline: Bool,
                    activeOutlineItemID: String?
                ) {
                    self.outlineItems = outlineItems
                    self.outlineLoadingState = outlineLoadingState
                    self.isShowingOutline = isShowingOutline
                    self.activeOutlineItemID = activeOutlineItemID
                }
            }

            struct SearchState: Equatable {
                var request: PDFSearchRequest?
            }

            let document: PDFDocument
            var pagingState: PagingState
            let documentIdentifierForLastViewedPageIndex: String?
            let initialPageIndex: Int?
            var outlineState: OutlineState
            var searchState: SearchState
        }

        struct FailedState: Equatable {
            var failureReason: FailureReason
            var isShowingDamagedFileAlert: Bool

            init(
                _ failureReason: FailureReason,
                isShowingDamagedFileAlert: Bool = false
            ) {
                self.failureReason = failureReason
                self.isShowingDamagedFileAlert = isShowingDamagedFileAlert
            }
        }

        enum FailureReason: Equatable {
            case downloadFailed
            case documentUnreadable
        }

        case loading(progress: Float?)
        case documentLocked(DocumentLockedState)
        case ready(ReadyState)
        case failed(FailedState)

        var isDocumentLocked: Bool { if case .documentLocked = self { true } else { false } }

        var isReady: Bool { if case .ready = self { true } else { false } }

        var isFailed: Bool { if case .failed = self { true } else { false } }
    }

    private(set) var state: ViewState = .loading(progress: nil)
    private(set) var thumbnailLoader: (any PDFThumbnailLoading)?

    private var failedState: ViewState.FailedState? {
        get { if case .failed(let failedState) = state { failedState } else { nil } }
        set { if let newValue, state.isFailed { state = .failed(newValue) } }
    }

    var isChromeHidden = false
    var isShowingThumbnails = false {
        didSet {
            if isShowingThumbnails {
                searchRequest = .dismiss
                if !oldValue, state.isReady { dependency.trackingUseCase.track(.thumbnailsOpened) }
            }
        }
    }
    var isProgrammaticallyScrollingToCurrentPage = false
    @ObservationIgnored private var isScrolledToTop = false
    @ObservationIgnored private var didApplyInitialPageNavigation = false
    @ObservationIgnored private var outlineLoadGeneration = 0
    @ObservationIgnored private var outlineLoadingOperation: (@Sendable () async -> PDFOutlineItems)?

    @ObservationIgnored private(set) var activeLoadAttempt: UUID?
    @ObservationIgnored var analyticsState = ViewState.AnalyticsState()

    let dependency: Dependency

    var fileName: String { dependency.fileName }

    private var readyState: ViewState.ReadyState? {
        get { if case .ready(let readyState) = state { readyState } else { nil } }
        set { if let newValue, state.isReady { state = .ready(newValue) } }
    }

    init(dependency: Dependency) {
        self.dependency = dependency
    }
}

// MARK: - Document loading

extension PDFViewerViewModel {

    /// The instance `MEGAPDFView` draws from; nil until ready.
    /// Thumbnails render from a separate instance, see
    /// `PDFViewerDocumentLoadingUseCase`.
    var pdfDocument: PDFDocument? {
        readyState?.document
    }

    var initialPageIndex: Int? {
        readyState?.initialPageIndex
    }

    /// Resolves the source to a file on disk and parses it. Re-entrant by
    /// design: SwiftUI restarts `.task` on every appearance, and a document
    /// already parsed is not resolved again.
    func loadDocumentFromSource() async {
        guard !state.isReady, !state.isDocumentLocked else { return }
        let attemptID = UUID()
        activeLoadAttempt = attemptID
        analyticsState.didTrackPasswordUnlock = false
        let events = dependency.documentURLUseCase.localDocumentURL(for: dependency.pdfDocumentSource)
        do {
            for try await event in events {
                guard !Task.isCancelled, activeLoadAttempt == attemptID else { return }
                switch event {
                case .progress(let progress):
                    state = .loading(progress: progress)
                case .ready(let url):
                    try await loadDocument(at: url, attemptID: attemptID)
                }
            }
        } catch {
            guard !Task.isCancelled, activeLoadAttempt == attemptID else { return }
            fail(.downloadFailed)
        }
    }

    private func loadDocument(at url: URL, attemptID: UUID) async throws {
        let loadingState = try await dependency.documentLoadingUseCase.loadDocument(at: url)
        try Task.checkCancellation()
        guard activeLoadAttempt == attemptID else { return }
        transitionToDocumentLoadingState(loadingState)
    }

    private func transitionToDocumentLoadingState(_ loadingState: PDFViewerDocumentLoadingState) {
        switch loadingState {
        case .documentLocked(let lockedState):
            state = .documentLocked(.init(
                document: lockedState.document,
                localDocumentURL: lockedState.localDocumentURL
            ))
        case .failed:
            fail(.documentUnreadable)
        case .ready(let readyState):
            transitionToReady(readyState)
            reportLoadOutcome(.loadSucceeded)
        }
    }

    private func transitionToReady(_ readyState: PDFViewerDocumentLoadingState.ReadyState) {
        outlineLoadingOperation = readyState.outlineLoadingState.loadOutline
        if let thumbnailDocument = readyState.thumbnailDocument {
            thumbnailLoader = PDFThumbnailLoader(document: thumbnailDocument)
        } else {
            thumbnailLoader = nil
        }
        state = .ready(ViewState.ReadyState(
            document: readyState.document,
            pagingState: ViewState.ReadyState.PagingState(
                currentPageIndex: 0,
                pageCount: readyState.document.pageCount
            ),
            documentIdentifierForLastViewedPageIndex:
                readyState.documentIdentifierForLastViewedPageIndex,
            initialPageIndex: readyState.initialPageIndex,
            outlineState: ViewState.ReadyState.OutlineState(
                outlineLoadingState: .init(readyState.outlineLoadingState)
            ),
            searchState: .init(request: nil)
        ))
    }

    private func fail(_ reason: ViewState.FailureReason) {
        reportLoadFailure(reason)
        isChromeHidden = false
        state = .failed(
            .init(reason,
                  isShowingDamagedFileAlert: reason == .documentUnreadable)
        )
    }
}

// MARK: - Failure state management

extension PDFViewerViewModel {
    var isShowingDamagedFileAlert: Bool {
        get { failedState?.isShowingDamagedFileAlert ?? false }
        set { failedState?.isShowingDamagedFileAlert = newValue }
    }

    /// Returns to the loading state and resolves the source again.
    func retryDocumentLoad() async {
        state = .loading(progress: nil)
        await loadDocumentFromSource()
    }
}

// MARK: - Search

extension PDFViewerViewModel {
    var searchRequest: PDFSearchRequest? {
        get { readyState?.searchState.request }
        set { readyState?.searchState.request = newValue }
    }

    func requestSearch() {
        guard state.isReady else { return }
        isShowingThumbnails = false
        isChromeHidden = false
        searchRequest = .present
        dependency.trackingUseCase.track(.searchToolbarSelected)
    }
}

// MARK: - Paging state management

extension PDFViewerViewModel {

    var currentPageIndex: Int {
        get { readyState?.pagingState.currentPageIndex ?? 0 }
        set {
            guard let pageCount = readyState?.pagingState.pageCount,
                  (0..<pageCount).contains(newValue) else { return }
            readyState?.pagingState.currentPageIndex = newValue
        }
    }

    var pageIndicatorText: String {
        if let lockedState, lockedState.document.pageCount > 0 {
            return Strings.Localizable.PdfPreview.pageOfTotal(1, lockedState.document.pageCount)
        }
        guard let pagingState = readyState?.pagingState else { return "" }
        return Strings.Localizable.PdfPreview.pageOfTotal(
            pagingState.currentPageIndex + 1,
            pagingState.pageCount
        )
    }

    func didSelectThumbnail(at pageIndex: Int) {
        if let pageCount = readyState?.pagingState.pageCount, (0..<pageCount).contains(pageIndex) {
            dependency.trackingUseCase.track(.thumbnailSelected)
        }
        scrollToPageIndex(pageIndex)
        isShowingThumbnails = false
    }

    private func scrollToPageIndex(_ pageIndex: Int) {
        guard let pageCount = readyState?.pagingState.pageCount,
              (0..<pageCount).contains(pageIndex) else { return }
        currentPageIndex = pageIndex
        isProgrammaticallyScrollingToCurrentPage = true
    }
}

// MARK: - Outline

extension PDFViewerViewModel {

    private var outlineState: ViewState.ReadyState.OutlineState? {
        get {
            readyState?.outlineState
        }
        set {
            guard let newValue else { return }
            readyState?.outlineState = newValue
        }
    }

    var outlineItems: [PDFOutlineItem] {
        outlineState?.outlineItems.inOutlineOrder ?? []
    }

    var pageSortedOutlineItems: [PDFOutlineItem] {
        outlineState?.outlineItems.inPageOrder ?? []
    }

    var isShowingOutline: Bool {
        get { outlineState?.isShowingOutline ?? false }
        set { outlineState?.isShowingOutline = newValue }
    }

    private(set) var isLoadingOutline: Bool {
        get { outlineState?.outlineLoadingState?.isLoadingOutline ?? false }
        set { outlineState?.outlineLoadingState?.isLoadingOutline = newValue }
    }

    private var shouldLoadOutline: Bool {
        outlineState?.outlineLoadingState?.shouldLoadOutline ?? false
    }

    var outlineDocumentURL: URL? {
        outlineState?.outlineLoadingState?.outlineDocumentURL
    }

    private(set) var activeOutlineItemID: String? {
        get { outlineState?.activeOutlineItemID }
        set { outlineState?.activeOutlineItemID = newValue }
    }

    var showsOutlineButton: Bool {
        guard let outlineState else { return false }
        return (outlineState.outlineLoadingState?.shouldLoadOutline ?? false) ||
            !outlineState.outlineItems.inOutlineOrder.isEmpty
    }

    /// Loads a pending outline after document readiness or a view appearance.
    /// - A new call supersedes any outline load still in progress.
    func loadOutlineIfNeeded() async {
        guard shouldLoadOutline, let outlineLoadingOperation else { return }
        outlineLoadGeneration += 1
        let generation = outlineLoadGeneration
        isLoadingOutline = true
        let items = await outlineLoadingOperation()
        guard generation == outlineLoadGeneration else { return }
        isLoadingOutline = false
        guard !Task.isCancelled else { return }
        updateOutlineState(loadedOutlineItems: items)
        self.outlineLoadingOperation = nil
    }

    private func updateOutlineState(loadedOutlineItems: PDFOutlineItems) {
        guard let previous = outlineState else { return }
        let isShowingOutline = previous.isShowingOutline &&
            !loadedOutlineItems.inOutlineOrder.isEmpty
        let activeOutlineItemID = isShowingOutline
            ? dependency.nearestOutlineItemUseCase.activeItem(
                forPageIndex: currentPageIndex,
                in: loadedOutlineItems.inPageOrder
            )?.id
            : nil
        outlineState = ViewState.ReadyState.OutlineState(
            outlineItems: loadedOutlineItems,
            outlineLoadingState: nil,
            isShowingOutline: isShowingOutline,
            activeOutlineItemID: activeOutlineItemID
        )
    }

    func didOpenOutline() {
        if showsOutlineButton, !isShowingOutline {
            dependency.trackingUseCase.track(.contentsOpened)
        }
        activeOutlineItemID = dependency.nearestOutlineItemUseCase.activeItem(
            forPageIndex: currentPageIndex,
            in: pageSortedOutlineItems
        )?.id
        isShowingOutline = true
        searchRequest = .dismiss
    }

    func didSelectOutlineItem(_ item: PDFOutlineItem) {
        if outlineItems.contains(item), let document = pdfDocument,
           (0..<document.pageCount).contains(item.pageIndex) {
            dependency.trackingUseCase.track(.contentsItemSelected)
        }
        scrollToPageIndex(item.pageIndex)
        isShowingThumbnails = false
        isShowingOutline = false
    }
}

// MARK: - Save

extension PDFViewerViewModel {

    /// Persists the current page as this document's resume point.
    /// - Saves nothing until a load has identified the document, which stops a
    ///   failed or abandoned load from clearing a stored row, since saving
    ///   index `0` deletes it.
    func saveLastReadPage() async {
        guard let readyState,
              let documentIdentifierForLastViewedPageIndex =
                readyState.documentIdentifierForLastViewedPageIndex
        else { return }
        // Until the jump to the stored page has landed, the stored page is
        // still the resume point, and the document shows its top instead.
        guard readyState.initialPageIndex == nil || didApplyInitialPageNavigation else { return }
        await dependency.lastPageUseCase.saveLastPageIndex(
            pageIndexForLastViewedAndLeftOff(),
            forDocumentIdentifier: documentIdentifierForLastViewedPageIndex
        )
    }

    /// Records the document in Continue Where You Left Off, or removes it once
    /// it is nearly finished, as the legacy viewer does.
    func recordLeftOffItem() async {
        guard let readyState,
              let node = dependency.node,
              !node.name.isEmpty,
              readyState.pagingState.pageCount > 0
        else { return }
        let nearCompletionFraction = 0.9
        let page = pageIndexForLastViewedAndLeftOff() + 1
        if Double(page) / Double(readyState.pagingState.pageCount) < nearCompletionFraction {
            await dependency.leftOffItemRecordUseCase.record(handle: node.handle, name: node.name)
        } else {
            await dependency.leftOffItemRecordUseCase.remove(handle: node.handle)
        }
    }

    func isScrolledToTopDidChange(_ isScrolledToTop: Bool) {
        self.isScrolledToTop = isScrolledToTop
    }

    func initialPageNavigationDidApply() {
        didApplyInitialPageNavigation = true
    }

    private func pageIndexForLastViewedAndLeftOff() -> Int {
        if let initialPageIndex = readyState?.initialPageIndex, !didApplyInitialPageNavigation {
            return initialPageIndex
        }
        // - `currentPageIndex` is the page at the viewport centre, which a
        //   short first page does not reach even when the document is at its
        //   top.
        // - `isScrolledToTop` is only re-checked on scrolls and page changes,
        //   so an inset change can leave it stale. Scrolling to the top again
        //   corrects it, which is enough for a resume point.
        return isScrolledToTop ? 0 : currentPageIndex
    }
}

extension PDFViewerViewModel {
    private var lockedState: ViewState.DocumentLockedState? {
        get { if case .documentLocked(let lockedState) = state { lockedState } else { nil } }
        set { if let newValue, state.isDocumentLocked { state = .documentLocked(newValue) } }
    }

    var password: String {
        get { lockedState?.password ?? "" }
        set { updatePassword(newValue) }
    }

    var showInvalidPasswordError: Bool { lockedState?.showInvalidPasswordError ?? false }

    var isSubmissionEnabled: Bool { lockedState?.isSubmissionEnabled == true && !password.isEmpty }

    var isDocumentLocked: Bool { state.isDocumentLocked }

    var isPasswordEntryPresented: Bool { lockedState?.isPasswordEntryPresented ?? false }

    var passwordRejectionCount: Int { lockedState?.passwordRejectionCount ?? 0 }

    func submitPassword() async {
        guard let submittedState = beginPasswordSubmission() else { return }
        let document = submittedState.document
        await unlockAndLoadDocument(
            document,
            documentUrl: submittedState.localDocumentURL,
            password: submittedState.password
        )
    }

    private func updatePassword(_ password: String) {
        // We clear the password in `beginPasswordSubmission()`, but
        // `SecureField` writes the cleared value back through the binding
        // after `rejectPasswordSubmission()`. This guard prevents the
        // write-back after the reject.
        guard lockedState?.isSubmissionEnabled == true,
              password != lockedState?.password else { return }
        lockedState?.password = password
        lockedState?.showInvalidPasswordError = false
    }

    private func beginPasswordSubmission() -> ViewState.DocumentLockedState? {
        guard isSubmissionEnabled, !Task.isCancelled, let lockedState else { return nil }
        self.lockedState?.isSubmissionEnabled = false
        self.lockedState?.password = ""
        return lockedState
    }

    private func rejectPasswordSubmission() {
        lockedState?.passwordRejectionCount += 1
        lockedState?.showInvalidPasswordError = true
        lockedState?.isSubmissionEnabled = true
    }

    private func unlockAndLoadDocument(
        _ document: PDFDocument,
        documentUrl: URL,
        password: String
    ) async {
        do {
            let loadingState = try await dependency.documentLoadingUseCase.unlockAndLoad(
                document: document,
                documentUrl: documentUrl,
                password: password
            )
            try Task.checkCancellation()
            guard isPasswordEntryPresented, lockedState?.document === document else { return }
            if case .documentLocked = loadingState {
                rejectPasswordSubmission()
            } else {
                trackPasswordUnlockIfNeeded()
                transitionToDocumentLoadingState(loadingState)
            }
        } catch {
            guard isPasswordEntryPresented, lockedState?.document === document else { return }
            if error is CancellationError || Task.isCancelled {
                cancelPasswordEntry()
            } else {
                fail(.documentUnreadable)
            }
        }
    }

    func cancelPasswordEntry() {
        guard isDocumentLocked else { return }
        lockedState?.isPasswordEntryPresented = false
        lockedState?.isSubmissionEnabled = false
        lockedState?.password = ""
        lockedState?.showInvalidPasswordError = false
    }
}
