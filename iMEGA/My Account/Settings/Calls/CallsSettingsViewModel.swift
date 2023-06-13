import MEGADomain

final class CallsSettingsViewModel {
    
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
    
    init(preferenceUseCase: any PreferenceUseCaseProtocol = PreferenceUseCase.default,
         analyticsEventUseCase: any AnalyticsEventUseCaseProtocol) {
        self.analyticsEventUseCase = analyticsEventUseCase
        $callsSoundNotificationPreference.useCase = preferenceUseCase
    }
}
