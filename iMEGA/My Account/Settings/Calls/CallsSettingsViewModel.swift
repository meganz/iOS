import MEGAAppPresentation
import MEGADomain
import MEGAUIComponent

final class CallsSettingsViewModel: ObservableObject {
    @Published private(set) var isEnabled: Bool?
    
    @PreferenceWrapper(key: .callsSoundNotification, defaultValue: true)
    var callsSoundNotificationPreference: Bool {
        didSet {
            if callsSoundNotificationPreference {
                analyticsEventUseCase.sendAnalyticsEvent(.meetings(.enableCallSoundNotifications))
            } else {
                analyticsEventUseCase.sendAnalyticsEvent(.meetings(.disableCallSoundNotifications))
            }
        }
    }
    
    private let analyticsEventUseCase: any AnalyticsEventUseCaseProtocol
    
    // MARK: - Life cycle
    
    init(preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
         analyticsEventUseCase: some AnalyticsEventUseCaseProtocol) {
        self.analyticsEventUseCase = analyticsEventUseCase
        $callsSoundNotificationPreference.useCase = preferenceUseCase
        
        self.isEnabled = callsSoundNotificationPreference
    }
    
    // MARK: - Internal
    
    func toggle(_ toggleValue: Bool) {
        isEnabled = toggleValue
        callsSoundNotificationPreference = toggleValue
    }
}
