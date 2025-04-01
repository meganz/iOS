import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation

final class SlideShowOptionCellViewModel: Identifiable, ObservableObject {
    let id: String
    let name: SlideShowOptionName
    let title: String
    let type: OptionType
    
    @Published var detail = ""
    @Published var children: [SlideShowOptionDetailCellViewModel]
    @Published var isOn = false
    
    enum OptionType {
        case none
        case detail
        case toggle
    }
    
    private let tracker: any AnalyticsTracking
    private var subscriptions = Set<AnyCancellable>()
    
    init(
        id: String = UUID().uuidString,
        name: SlideShowOptionName,
        title: String,
        type: SlideShowOptionCellViewModel.OptionType,
        children: [SlideShowOptionDetailCellViewModel],
        isOn: Bool = false,
        tracker: some AnalyticsTracking
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.type = type
        self.children = children
        self.isOn = isOn
        self.tracker = tracker
        detail = type == .detail ? (children.first(where: { $0.isSelected })?.title ?? "") : ""
        
        subscribeToRepeatIsOnChangedAnalyticEventSender()
    }
    
    func didSelectChild(_ child: SlideShowOptionDetailCellViewModel) {
        sendTappedEvent(child: child)
        
        guard type == .detail else {
            return
        }
        children.forEach({ $0 .isSelected = $0.id == child.id })
        detail = child.title
    }
    
    private func sendTappedEvent(child: SlideShowOptionDetailCellViewModel) {
        switch child.name {
        case .none, .speed, .order, .repeat:
            break
        case .speedNormal:
            tracker.trackAnalyticsEvent(with: SlideshowSettingSpeedNormalButtonEvent())
        case .speedFast:
            tracker.trackAnalyticsEvent(with: SlideshowSettingSpeedFastButtonEvent())
        case .speedSlow:
            tracker.trackAnalyticsEvent(with: SlideshowSettingSpeedSlowButtonEvent())
        case .orderShuffle:
            tracker.trackAnalyticsEvent(with: SlideshowSettingOrderShuffleButtonEvent())
        case .orderNewest:
            tracker.trackAnalyticsEvent(with: SlideshowSettingOrderNewestButtonEvent())
        case .orderOldest:
            tracker.trackAnalyticsEvent(with: SlideshowSettingOrderOldestButtonEvent())
        }
    }
    
    private func subscribeToRepeatIsOnChangedAnalyticEventSender() {
        guard name == .`repeat` else {
            return
        }
        
        $isOn
            .dropFirst()
            .sink { [weak self] isOn in
                guard let self else {
                    return
                }
                
                switch isOn {
                case true:
                    tracker.trackAnalyticsEvent(with: SlideshowSettingRepeatOnButtonEvent())
                case false:
                    tracker.trackAnalyticsEvent(with: SlideshowSettingRepeatOffButtonEvent())
                }
            }
            .store(in: &subscriptions)
    }
}
