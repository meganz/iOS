import MEGAChatSdk
import MEGADomain

public struct ChangeSfuServerRepository: ChangeSfuServerRepositoryProtocol {
    public static var newRepo: ChangeSfuServerRepository {
        ChangeSfuServerRepository()
    }
    
    public func changeSfuServer(to serverId: Int) {
        MEGAChatSdk.sharedChatSdk.setSFU(serverId)
    }
}
