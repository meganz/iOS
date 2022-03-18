@testable import MEGA

struct MockNetworkMonitorRepository: NetworkMonitorRepositoryProtocol {
    var connected = false
    
    func networkPathChanged(completion: @escaping (Bool) -> Void) {
        completion(connected)
    }
}
