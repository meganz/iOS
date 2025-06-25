import MEGAPreference

public protocol ManageLogsUseCaseProtocol: Sendable {
    func toggleLogs(with logMetadata: LogMetadataEntity)
}

public struct ManageLogsUseCase: ManageLogsUseCaseProtocol {
    private var repository: any LogSettingRepositoryProtocol
    
    @PreferenceWrapper(key: PreferenceKeyEntity.logging, defaultValue: false)
    private var isLoggingEnabled: Bool
    
    public init(repository: some LogSettingRepositoryProtocol,
                preferenceUseCase: some PreferenceUseCaseProtocol) {
        self.repository = repository
        $isLoggingEnabled.useCase = preferenceUseCase
    }
    
    public func toggleLogs(with logMetadata: LogMetadataEntity) {
        repository.toggleLogs(enable: isLoggingEnabled, with: logMetadata)
    }
}
