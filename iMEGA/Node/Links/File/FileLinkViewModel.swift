import MEGAAnalyticsiOS
import MEGAAppPresentation

@MainActor
public final class FileLinkViewModel: ViewModelType {
    public enum Action: ActionType {
        case trackSendToChatFileLinkNoAccountLogged
        case trackSendToChatFileLink
    }
    
    public enum Command: CommandType { }

    private let tracker: any AnalyticsTracking

    public init(
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.tracker = tracker
    }
    
    public var invokeCommand: ((Command) -> Void)?

    public func dispatch(_ action: Action) {
        switch action {
        case .trackSendToChatFileLink:
            trackSendToChatFileLinkEvent()
        case .trackSendToChatFileLinkNoAccountLogged:
            trackSendToChatFileLinkNoAccountLoggedEvent()
        }
    }
    
    func trackSendToChatFileLinkNoAccountLoggedEvent() {
        tracker.trackAnalyticsEvent(with: SendToChatFileLinkNoAccountLoggedButtonPressedEvent())
    }

    func trackSendToChatFileLinkEvent() {
        tracker.trackAnalyticsEvent(with: SendToChatFileLinkButtonPressedEvent())
    }
}
