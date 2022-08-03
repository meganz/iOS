@testable import MEGA
import MEGAFoundation

final class MockDispatchQueue: DispatchQueueProtocol {
    func async(qos: DispatchQoS, closure: @escaping () -> Void) {
        closure()
    }
}
