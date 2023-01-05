import Foundation

public protocol LogUseCaseProtocol {
    func shouldEnableLogs() -> Bool
}

public struct LogUseCase<T: PreferenceUseCaseProtocol, U: AppConfigurationRepositoryProtocol>: LogUseCaseProtocol {
    @PreferenceWrapper(key: .logging, defaultValue: false)
    private var isLoggingEnabled: Bool
    private var appConfigurationRepository: U
    
    public init(preferenceUseCase: T, appConfigurationRepository: U) {
        self.appConfigurationRepository = appConfigurationRepository
        $isLoggingEnabled.useCase = preferenceUseCase
    }
    
    public func shouldEnableLogs() -> Bool {
        isLoggingEnabled || appConfigurationRepository.configuration == .testFlight || appConfigurationRepository.configuration == .qa
    }
}
