import MEGADomain

struct ChangeSfuServerRepository: ChangeSfuServerRepositoryProtocol {
    static var newRepo: ChangeSfuServerRepository {
        ChangeSfuServerRepository()
    }
    
    func changeSfuServer(to serverId: Int) {
        MEGAChatSdk.shared.setSFU(serverId)
    }
}
