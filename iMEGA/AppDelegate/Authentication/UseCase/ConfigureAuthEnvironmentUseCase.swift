import ChatRepo
import LogRepo
import MEGAAppSDKRepo
import MEGAAuthentication
import MEGADomain
import MEGAPreference

/// `ConfigureAuthEnvironmentUseCase` acts as a bridge between the `MEGAAuthentication` domain and `MEGADomain`.
///
/// This use case coordinates authentication environment configuration, debug logging, and API environment changes
/// by delegating to the appropriate domain-specific use cases and entities.
struct ConfigureAuthEnvironmentUseCase: ConfigureAuthEnvironmentUseCaseProtocol {
    private let logMetadataEntity: LogMetadataEntity
    private var apiEnvironmentUseCase: any APIEnvironmentUseCaseProtocol
    private let manageLogsUseCase: any ManageLogsUseCaseProtocol

    @PreferenceWrapper(key: PreferenceKeyEntity.logging, defaultValue: false)
    var isDebugLoggingEnabled: Bool
    
    init(
        logMetadataEntity: LogMetadataEntity,
        preferenceUseCase: any PreferenceUseCaseProtocol,
        apiEnvironmentUseCase: some APIEnvironmentUseCaseProtocol,
        manageLogsUseCase: some ManageLogsUseCaseProtocol
    ) {
        self.logMetadataEntity = logMetadataEntity
        self.apiEnvironmentUseCase = apiEnvironmentUseCase
        self.manageLogsUseCase = manageLogsUseCase
        $isDebugLoggingEnabled.useCase = preferenceUseCase
    }
    
    var environments: [APIEnvironmentTypeEntity] {
        APIEnvironmentEntity.allCases.map { $0.rawValue }
    }
    
    func toggleDebugLogging() {
        manageLogsUseCase.toggleLogs(
            with: logMetadataEntity
        )
    }
    
    mutating func changeAPIURL(_ environment: APIEnvironmentTypeEntity) {
        guard let environment = MEGADomain.APIEnvironmentEntity(rawValue: environment) else {
            return
        }
        apiEnvironmentUseCase.changeAPIURL(environment)
    }
}
