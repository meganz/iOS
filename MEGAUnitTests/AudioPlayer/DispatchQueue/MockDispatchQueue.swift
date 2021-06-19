@testable import MEGA

final class MockDispatchQueue: DispatchQueueProtocol {
    func async(qos: DispatchQoS, closure: @escaping () -> Void) {
        closure()
    }
}
