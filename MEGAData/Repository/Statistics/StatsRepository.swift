import Foundation

struct StatsRepository: StatsRepositoryProtocol {
    static var newRepo: StatsRepository {
        StatsRepository(sdk: MEGASdkManager.sharedMEGASdk())
    }
    
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func sendStatsEvent(_ event: StatsEventEntity) {
        sdk.sendEvent(event.toMEGAEventCode(), message: event.message)
    }
}
