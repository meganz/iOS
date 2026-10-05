import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain

@objc final class AVViewModel: NSObject {
    private let videoPlayerScreenEvent = VideoPlayerScreenEvent()
    
    private let tracker: any AnalyticsTracking
    private let leftOffItemRecordUseCase: any LeftOffItemRecordUseCaseProtocol
    private(set) var leftOffItemTask: Task<Void, Never>?
    
    init(
        tracker: some AnalyticsTracking = DIContainer.tracker,
        leftOffItemRecordUseCase: some LeftOffItemRecordUseCaseProtocol = LeftOffItemsRecordUseCase.shared
    ) {
        self.tracker = tracker
        self.leftOffItemRecordUseCase = leftOffItemRecordUseCase
    }
    
    @objc func onViewDidLoad() {
        tracker.trackAnalyticsEvent(with: videoPlayerScreenEvent)
    }

    @objc func processLeftOffItem(handle: HandleEntity, name: String?, shouldRecord: Bool) {
        leftOffItemTask = Task { [leftOffItemRecordUseCase] in
            if shouldRecord {
                guard let name else { return }

                await leftOffItemRecordUseCase.record(handle: handle, name: name)
            } else {
                await leftOffItemRecordUseCase.remove(handle: handle)
            }
        }
    }
}
