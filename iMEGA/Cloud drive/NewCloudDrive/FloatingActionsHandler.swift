import CloudDrive
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain

/// This is the handler for handling actions in the  FAB (+) button in CloudDrive
final class FloatingActionsHandler: FloatingActionsHandlerProtocol {
    private let tracker: any AnalyticsTracking
    private let nodeInsertionRouter: any NodeInsertionRouting
    private let nodeSource: NodeSource

    var openLinkRouter: OpenLinkRouter?

    init(
        tracker: some AnalyticsTracking,
        nodeInsertionRouter: some NodeInsertionRouting,
        nodeSource: NodeSource
    ) {
        self.tracker = tracker
        self.nodeInsertionRouter = nodeInsertionRouter
        self.nodeSource = nodeSource
    }

    func handle(action: FloatingActionEntity) {
        guard
            case let .node(nodeProvider) = nodeSource,
            let node = nodeProvider()
        else { return }

        switch action {
        case .chooseFromPhotos:
            trackChooseFromPhotosEvent()
            Task { [nodeInsertionRouter] in
                await nodeInsertionRouter.choosePhotoVideo(for: node)
            }
        case .capture:
            nodeInsertionRouter.capturePhotoVideo(for: node)
        case .importFrom:
            trackImportFromFilesEvent()
            nodeInsertionRouter.importFromFiles(for: node)
        case .scanDocument:
            nodeInsertionRouter.scanDocument(for: node)
        case .newFolder:
            trackNewFolderEvent()
            nodeInsertionRouter.createNewFolder(for: node)
        case .newTextFile:
            trackNewTextFileEvent()
            nodeInsertionRouter.createTextFileAlert(for: node)
        case .openLink:
            openLinkRouter?.start()
        }
    }

    private func trackChooseFromPhotosEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveChooseFromPhotosMenuToolbarEvent())
    }

    private func trackImportFromFilesEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveImportFromFilesMenuToolbarEvent())
    }

    private func trackNewFolderEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveNewFolderMenuToolbarEvent())
    }

    private func trackNewTextFileEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveNewTextFileMenuToolbarEvent())
    }
}
