import MEGAChatSdk
import MEGADomain

public final class WaitingRoomRepository: WaitingRoomRepositoryProtocol {
    private let chatSdk: MEGAChatSdk
    
    public static var newRepo: WaitingRoomRepository {
        WaitingRoomRepository(chatSdk: MEGAChatSdk.sharedChatSdk)
    }
    
    public init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }
    
    public func userName() -> String {
        chatSdk.myFullname ?? ""
    }
}
