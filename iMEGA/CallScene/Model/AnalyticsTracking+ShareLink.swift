import MEGAAnalyticsiOS
import MEGAAppPresentation

// as this action is tracked from multiple places scattered around the code,
// this simple tool allows to know which one is triggered from where
enum ShareLinkTrackingScenario {
    case callEmptyAlert
    case callNavBarButton
    case participantListBottomButton
    case meetingOptionsMenu
}

extension AnalyticsTracking {
    
    func trackShareLink(_ scenario: ShareLinkTrackingScenario) {
        switch scenario {
        case .callEmptyAlert:
            trackAnalyticsEvent(with: ShareLinkPressedEvent())
        case .callNavBarButton:
            trackAnalyticsEvent(with: ShareLinkBarButtonPressedEvent())
        case .participantListBottomButton:
            trackAnalyticsEvent(with: ParticipantListShareMeetingLinkPressedEvent())
        case .meetingOptionsMenu:
            trackAnalyticsEvent(with: CallScreenMenuOptionsShareLinkMenuItemEvent())
        }
    }
}
