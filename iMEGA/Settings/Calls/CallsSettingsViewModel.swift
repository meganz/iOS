
final class CallsSettingsViewModel {
    
    @PreferenceWrapper(key: .callsSoundNotification, defaultValue: true)
    var callsSoundNotificationPreference: Bool
    
    init(preferenceUseCase: PreferenceUseCaseProtocol = PreferenceUseCase.default) {
        $callsSoundNotificationPreference.useCase = preferenceUseCase
    }
}
