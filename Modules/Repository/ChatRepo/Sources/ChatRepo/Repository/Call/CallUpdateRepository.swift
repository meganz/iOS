import MEGAChatSdk
import MEGADomain
import MEGASwift

public struct CallUpdateRepository: CallUpdateRepositoryProtocol {
    public static var newRepo: CallUpdateRepository {
        CallUpdateRepository(chatSdk: .sharedChatSdk, callUpdateProvider: CallUpdateProvider(sdk: .sharedChatSdk))
    }
    
    private let chatSdk: MEGAChatSdk
    private let callUpdateProvider: any CallUpdateProviderProtocol

    public init(chatSdk: MEGAChatSdk, callUpdateProvider: some CallUpdateProviderProtocol) {
        self.chatSdk = chatSdk
        self.callUpdateProvider = callUpdateProvider
    }
    
    public var callUpdate: AnyAsyncSequence<CallEntity> {
        callUpdateProvider.callUpdate
    }
}
