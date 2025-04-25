import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain

@objc public final class PhotoBrowserViewModel: NSObject, ViewModelType {
    public enum Action: ActionType {
        case onViewDidLoad
        case onViewWillAppear
        case onViewWillDisappear
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
}
