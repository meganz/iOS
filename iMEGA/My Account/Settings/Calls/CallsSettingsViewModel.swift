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
    
    private let analyticsEventUseCase: AnalyticsEventUseCaseProtocol
    
    init(preferenceUseCase: PreferenceUseCaseProtocol = PreferenceUseCase.default,
         analyticsEventUseCase: AnalyticsEventUseCaseProtocol) {
        self.analyticsEventUseCase = analyticsEventUseCase
        $callsSoundNotificationPreference.useCase = preferenceUseCase
    }
}
