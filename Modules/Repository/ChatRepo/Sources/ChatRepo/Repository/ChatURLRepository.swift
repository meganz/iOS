import MEGAChatSdk
import MEGADomain

public struct ChatURLRepository: ChatURLRespositoryProtocol {
    public static var newRepo: ChatURLRepository {
        ChatURLRepository(sdk: .sharedChatSdk)
    }
    
    private let sdk: MEGAChatSdk

    private init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
    
    public func refreshUrls() {
        sdk.refreshUrls()
    }
}
