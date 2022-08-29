import MEGADomain

final class CallsSettingsViewModel {
    
    @PreferenceWrapper(key: .callsSoundNotification, defaultValue: true)
    var callsSoundNotificationPreference: Bool {
        didSet {
            if callsSoundNotificationPreference {
                statsUseCase.sendEnableSoundNotificationStats()
            } else {
                statsUseCase.sendDisableSoundNotificationStats()
            }
        }
    }
    
    private let statsUseCase: MeetingStatsUseCaseProtocol
    
    init(preferenceUseCase: PreferenceUseCaseProtocol = PreferenceUseCase.default,
         statsUseCase: MeetingStatsUseCaseProtocol) {
        self.statsUseCase = statsUseCase
        $callsSoundNotificationPreference.useCase = preferenceUseCase
    }
}
