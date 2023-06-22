import MEGAData
import MEGADomain

struct APIEnvironmentRepository: APIEnvironmentRepositoryProtocol {
    static var newRepo: APIEnvironmentRepository {
        APIEnvironmentRepository(sdk: MEGASdk.shared, folderSdk: MEGASdk.sharedFolderLink, chatSdk: MEGAChatSdk.shared, credentialRepository: CredentialRepository.newRepo)
    }
    
    private let sdk: MEGASdk
    private let folderSdk: MEGASdk
    private let chatSdk: MEGAChatSdk
    private let credentialRepository: any CredentialRepositoryProtocol
    
    @PreferenceWrapper(key: .apiEnvironment, defaultValue: 0, useCase: PreferenceUseCase.default)
    private var apiEnvironment: Int
    
    private enum Constants {
        static let productionSDKUrl = "https://g.api.mega.co.nz/"
        static let stagingSDKUrl = "https://staging.api.mega.co.nz/"
        static let staging444SDKUrl = "https://staging.api.mega.co.nz:444/"
        static let sandbox3SDKUrl = "https://api-sandbox3.developers.mega.co.nz/"
    }
    
    init(sdk: MEGASdk, folderSdk: MEGASdk, chatSdk: MEGAChatSdk, credentialRepository: any CredentialRepositoryProtocol) {
        self.sdk = sdk
        self.folderSdk = folderSdk
        self.chatSdk = chatSdk
        self.credentialRepository = credentialRepository
    }
    
    func changeAPIURL(_ environment: APIEnvironmentEntity) {
        switch environment {
        case .production:
            sdk.changeApiUrl(Constants.productionSDKUrl, disablepkp: false)
            folderSdk.changeApiUrl(Constants.productionSDKUrl, disablepkp: false)
        case .staging:
            sdk.changeApiUrl(Constants.stagingSDKUrl, disablepkp: false)
            folderSdk.changeApiUrl(Constants.stagingSDKUrl, disablepkp: false)
        case .staging444:
            sdk.changeApiUrl(Constants.staging444SDKUrl, disablepkp: true)
            folderSdk.changeApiUrl(Constants.staging444SDKUrl, disablepkp: true)
        case .sandbox3:
            sdk.changeApiUrl(Constants.sandbox3SDKUrl, disablepkp: true)
            folderSdk.changeApiUrl(Constants.sandbox3SDKUrl, disablepkp: true)
        }
        
        apiEnvironment = environment.toEnvironmentCode()
        
        if let sessionId = credentialRepository.sessionId() {
            sdk.fastLogin(withSession: sessionId)
            chatSdk.refreshUrls()
        }
    }
}
