import MEGAAnalyticsiOS
import MEGAAppPresentation

public enum PDFViewerAnalyticsSource: String, CaseIterable, Sendable {
    case offline
    case fileLink = "file_link"
    case folderLink = "folder_link"
    case chat
    case node
    case unknown
}

public enum PDFViewerAnalyticsFailure: String, CaseIterable, Sendable {
    case downloadFailed = "download_failed"
    case documentUnreadable = "document_unreadable"
}

public enum PDFViewerAnalyticsMoreAction: String, CaseIterable, Sendable {
    case makeAvailableOffline = "make_available_offline"
    case addToCloudDrive = "add_to_cloud_drive"
    case downloadToDevice = "download_to_device"
    case shareLink = "share_link"
    case manageLink = "manage_link"
    case removeLink = "remove_link"
    case sendToChat = "send_to_chat"
    case hide
    case unhide
    case moveToRubbishBin = "move_to_rubbish_bin"
    case info
    case viewVersions = "view_versions"
    case remove
    case restore
}

public enum PDFViewerAnalyticsEvent: Equatable, Sendable {
    case screenPresented
    case closed
    case loadSucceeded
    case loadFailed(PDFViewerAnalyticsFailure)
    case passwordUnlocked
    case moreMenuOpened
    case thumbnailsOpened
    case thumbnailSelected
    case contentsOpened
    case contentsItemSelected
    case searchToolbarSelected
    case searchSessionStarted
    case searchResultItemSelected
    case downloadRequested(PDFViewerAnalyticsSource)
    case moreActionSelected(PDFViewerAnalyticsMoreAction, PDFViewerAnalyticsSource)
    case offlineFileOpened
}

public protocol PDFViewerTrackingUseCaseProtocol: Sendable {
    func track(_ event: PDFViewerAnalyticsEvent)
}

public struct PDFViewerTrackingUseCase: PDFViewerTrackingUseCaseProtocol {
    private let tracker: any AnalyticsTracking

    public init(tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.tracker = tracker
    }

    public func track(_ event: PDFViewerAnalyticsEvent) {
        let identifier: any EventIdentifier = switch event {
        case .screenPresented: PdfViewerScreenEvent.shared
        case .closed: PdfViewerClosedEvent.shared
        case .loadSucceeded: PdfViewerLoadSucceededEvent.shared
        case .loadFailed(let reason): PdfViewerLoadFailedEvent(reason: reason.rawValue)
        case .passwordUnlocked: PdfViewerPasswordUnlockedEvent.shared
        case .moreMenuOpened: PdfViewerMoreMenuOpenedEvent.shared
        case .thumbnailsOpened: PdfViewerThumbnailsOpenedEvent.shared
        case .thumbnailSelected: PdfViewerThumbnailSelectedEvent.shared
        case .contentsOpened: PdfViewerContentsOpenedEvent.shared
        case .contentsItemSelected: PdfViewerContentsItemSelectedEvent.shared
        case .searchToolbarSelected: PdfViewerSearchMenuToolbarEvent.shared
        case .searchSessionStarted: PdfViewerSearchSessionStartedEvent.shared
        case .searchResultItemSelected: PdfViewerSearchResultItemSelectedEvent.shared
        case .downloadRequested(let source): PdfViewerDownloadRequestedEvent(source: source.rawValue)
        case .moreActionSelected(let action, let source):
            PdfViewerMoreActionSelectedEvent(action: action.rawValue, source: source.rawValue)
        case .offlineFileOpened: FileOpenEvent(fileType: "pdf", context: .offline)
        }
        tracker.trackAnalyticsEvent(with: identifier)
    }
}
