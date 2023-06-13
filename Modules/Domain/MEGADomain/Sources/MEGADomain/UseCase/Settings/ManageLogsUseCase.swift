
public protocol ManageLogsUseCaseProtocol {
    func toggleLogs()
}

public struct ManageLogsUseCase: ManageLogsUseCaseProtocol {
    private var repository: any LogSettingRepositoryProtocol
    
    @PreferenceWrapper(key: .logging, defaultValue: false)
    private var isLoggingEnabled: Bool
    
    public init(repository: any LogSettingRepositoryProtocol,
                preferenceUseCase: any PreferenceUseCaseProtocol) {
        self.repository = repository
        $isLoggingEnabled.useCase = preferenceUseCase
    }
    
    public func toggleLogs() {
        repository.toggleLogs(enable: isLoggingEnabled)
    }
}
