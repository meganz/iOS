
public protocol ManageLogsUseCaseProtocol {
    func toggleLogs()
}

public struct ManageLogsUseCase: ManageLogsUseCaseProtocol {
    private var repository: LogSettingRepositoryProtocol
    
    @PreferenceWrapper(key: .logging, defaultValue: false)
    private var isLoggingEnabled: Bool
    
    public init(repository: LogSettingRepositoryProtocol, preferenceUseCase: PreferenceUseCaseProtocol) {
        self.repository = repository
        $isLoggingEnabled.useCase = preferenceUseCase
    }
    
    public func toggleLogs() {
        repository.toggleLogs(enable: isLoggingEnabled)
    }
}
