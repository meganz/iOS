import Foundation
import MEGAPreference

public protocol LogUseCaseProtocol {
    func shouldEnableLogs() -> Bool
}

public struct LogUseCase<T: PreferenceUseCaseProtocol, U: AppEnvironmentUseCaseProtocol>: LogUseCaseProtocol {
    @PreferenceWrapper(key: PreferenceKeyEntity.logging, defaultValue: false)
    private var isLoggingEnabled: Bool
    private var appEnvironment: U
    
    public init(preferenceUseCase: T, appEnvironment: U) {
        self.appEnvironment = appEnvironment
        $isLoggingEnabled.useCase = preferenceUseCase
    }
    
    public func shouldEnableLogs() -> Bool {
        isLoggingEnabled || appEnvironment.configuration == .testFlight || appEnvironment.configuration == .qa
    }
}
