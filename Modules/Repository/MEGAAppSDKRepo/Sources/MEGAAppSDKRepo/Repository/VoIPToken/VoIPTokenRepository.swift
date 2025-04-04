import MEGADomain
import MEGASdk

public struct VoIPTokenRepository: VoIPTokenRepositoryProtocol {
    public static var newRepo: VoIPTokenRepository {
        VoIPTokenRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk
 
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func registerVoIPDeviceToken(_ token: String) {
        sdk.registeriOSVoIPdeviceToken(token)
    }
}
