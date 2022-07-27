@testable import MEGA

class MockReachabilityUseCase: ReachabilityUseCaseProtocol {
    var isReacheable: Bool = true
    var registerNetworkChangeListener_calledTimes = 0
    
    func isReachable() -> Bool {
        isReacheable
    }
    
    func registerNetworkChangeListener(_ lisetner: @escaping (NetworkReachabilityEntity) -> Void) {
        registerNetworkChangeListener_calledTimes = 1
    }
}
