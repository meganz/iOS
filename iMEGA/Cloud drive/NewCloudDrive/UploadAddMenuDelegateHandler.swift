import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain

/// This is the handler for handling plus (+) button in cloud  drive to implement way of adding items to Cloud Drive
/// Could be used to  handle actions:
/// 1. [SAO-817] Add Photos to Cloud Drive
/// 2. [SAO-818] Create a New Folder
/// 3. [SAO-819] Create a New text file
/// 4. [SAO-839] Handle document import flow
/// 5. [SAO-841] Handle document scanning
final class UploadAddMenuDelegateHandler: UploadAddMenuDelegate {
    private let tracker: any AnalyticsTracking
    private let nodeInsertionRouter: any NodeInsertionRouting
    private let nodeSource: NodeSource

    init(
        tracker: some AnalyticsTracking,
        nodeInsertionRouter: some NodeInsertionRouting,
        nodeSource: NodeSource
    ) {
        self.tracker = tracker
        self.nodeInsertionRouter = nodeInsertionRouter
        self.nodeSource = nodeSource
    }

    func uploadAddMenu(didSelect action: UploadAddActionEntity) {
        guard
            case let .node(nodeProvider) = nodeSource,
            let node = nodeProvider()
        else { return }

        switch action {
        case .chooseFromPhotos:
            trackChooseFromPhotosEvent()
            Task {
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
        case .importFolderLink:
            break
        }
        
        trackOpenAddMenuEvent()
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
    
    private func trackOpenAddMenuEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveAddMenuEvent())
    }
}
