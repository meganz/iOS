@testable import MEGA

struct MockNetworkMonitorUseCase: NetworkMonitorUseCaseProtocol {
    
    var connected = false
    
    func networkPathChanged(completion: @escaping (Bool) -> Void) {
        completion(connected)
    }
}
