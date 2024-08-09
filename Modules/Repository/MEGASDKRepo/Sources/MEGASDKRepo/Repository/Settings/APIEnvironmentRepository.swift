import MEGADomain
import MEGARepo
import MEGASdk

public struct APIEnvironmentRepository: APIEnvironmentRepositoryProtocol {
    public static var newRepo: APIEnvironmentRepository {
        APIEnvironmentRepository(sdk: .sharedSdk, folderSdk: .sharedFolderLinkSdk, credentialRepository: CredentialRepository.newRepo)
    }
    
    private let sdk: MEGASdk
    private let folderSdk: MEGASdk
    private let credentialRepository: any CredentialRepositoryProtocol
    
    @PreferenceWrapper(key: .apiEnvironment, defaultValue: 0, useCase: PreferenceUseCase(repository: PreferenceRepository.newRepo))
    private var apiEnvironment: Int
    
    private enum Constants {
        static let productionSDKUrl = "https://g.api.mega.co.nz/"
        static let stagingSDKUrl = "https://staging.api.mega.co.nz/"
        static let bt1444SDKUrl = "https://bt1.api.mega.co.nz:444/"
        static let sandbox3SDKUrl = "https://api-sandbox3.developers.mega.co.nz/"
    }
    
    public init(sdk: MEGASdk, folderSdk: MEGASdk, credentialRepository: any CredentialRepositoryProtocol) {
        self.sdk = sdk
        self.folderSdk = folderSdk
        self.credentialRepository = credentialRepository
    }
    
    public func changeAPIURL(_ environment: APIEnvironmentEntity, onUserSessionAvailable: () -> Void) {
        switch environment {
        case .production:
            sdk.changeApiUrl(Constants.productionSDKUrl, disablepkp: false)
            folderSdk.changeApiUrl(Constants.productionSDKUrl, disablepkp: false)
        case .staging:
            sdk.changeApiUrl(Constants.stagingSDKUrl, disablepkp: false)
            folderSdk.changeApiUrl(Constants.stagingSDKUrl, disablepkp: false)
        case .bt1444:
            sdk.changeApiUrl(Constants.bt1444SDKUrl, disablepkp: true)
            folderSdk.changeApiUrl(Constants.bt1444SDKUrl, disablepkp: true)
        case .sandbox3:
            sdk.changeApiUrl(Constants.sandbox3SDKUrl, disablepkp: true)
            folderSdk.changeApiUrl(Constants.sandbox3SDKUrl, disablepkp: true)
        }
        
        apiEnvironment = environment.toEnvironmentCode()
        
        if let sessionId = credentialRepository.sessionId() {
            sdk.fastLogin(withSession: sessionId)
            onUserSessionAvailable()
        }
    }
}
