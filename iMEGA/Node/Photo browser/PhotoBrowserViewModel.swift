import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import NodeBackgroundDownloader

@objc public final class PhotoBrowserViewModel: NSObject, ViewModelType {
    public enum Action: ActionType {
        case onViewDidLoad
        case onViewWillAppear
        case onViewWillDisappear
        case nodeDownloadStarted(NodeEntity)
        case downloadFileLink(URL)
    }
    
    public enum Command: CommandType, Equatable {
        case nodesUpdate([NodeEntity])
    }
    
    public var invokeCommand: ((Command) -> Void)?
    
    public func dispatch(_ action: Action) {
        switch action {
        case .onViewDidLoad:
            onViewDidLoad()
        case .onViewWillAppear:
            onViewWillAppear()
        case .onViewWillDisappear:
            onViewWillDisappear()
        case let .nodeDownloadStarted(node):
            if #available(iOS 26.0, *) {
                processBackgroundDownload(for: node)
            }
        case let .downloadFileLink(url):
            if #available(iOS 26.0, *) {
                downloadFileLink(url: url)
            }
        }
    }
    
    private let photoBrowserUseCase: any PhotoBrowserUseCaseProtocol
    
    var monitorNodeUpdatesTask: Task<Void, Never>? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    private let tracker: any AnalyticsTracking
    
    init(
        tracker: some AnalyticsTracking = DIContainer.tracker,
        photoBrowserUseCase: some PhotoBrowserUseCaseProtocol
    ) {
        self.tracker = tracker
        self.photoBrowserUseCase = photoBrowserUseCase
    }
    
    private func onViewWillAppear() {
        monitorNodeUpdatesTask = Task { [weak self, photoBrowserUseCase] in
            for await nodeEntities in photoBrowserUseCase.nodeUpdates {
                self?.invokeCommand?(.nodesUpdate(nodeEntities))
            }
        }
    }
    
    private func onViewDidLoad() {
        tracker.trackAnalyticsEvent(with: DIContainer.photoPreviewScreenEvent)
    }
    
    private func onViewWillDisappear() {
        monitorNodeUpdatesTask = nil
    }
    
    @objc func trackAnalyticsSaveToDeviceMenuToolbarEvent() {
        tracker.trackAnalyticsEvent(
            with: DIContainer.photoPreviewSaveToDeviceMenuToolbarEvent)
    }
    
    @objc func trackHideNodeMenuEvent() {
        tracker.trackAnalyticsEvent(with: ImagePreviewHideNodeMenuToolBarEvent())
    }

    @objc func trackAddToAlbumMenuItemEvent() {
        tracker.trackAnalyticsEvent(with: AddToAlbumMenuItemEvent())
    }
    
    @available(iOS 26.0, *)
    private func processBackgroundDownload(for node: NodeEntity) {
        let featureEnabled = DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosBackgroundContinuedProcessingTransfer)
        // Note: consider using MediaUseCase
        let isVideo = node.name.fileExtensionGroup.isVideo
        
        guard featureEnabled && isVideo else { return }
        
        Task {
            await BackgroundDownloadHandler.shared.handleBackgroundDownload(for: node)
        }
        tracker.trackAnalyticsEvent(with: PhotoPreviewMakeAvailableOfflineBGContinuedProcessingTaskMenuItemEvent())
    }
    
    @available(iOS 26.0, *)
    private func downloadFileLink(url: URL) {
        let fileLink = FileLinkEntity(linkURL: url)
        Task {
            do {
                let node = try await photoBrowserUseCase.nodeFor(fileLink: fileLink)
                processBackgroundDownload(for: node)
            } catch {
                MEGALogWarning("[Photo Browser] Failed to get node for file link: \(url) with error: \(error)")
            }
        }
    }
}
