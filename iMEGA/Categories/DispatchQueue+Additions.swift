import Foundation

protocol DispatchQueueProtocol {
    func async(qos: DispatchQoS, closure: @escaping () -> Void)
}

extension DispatchQueue: DispatchQueueProtocol {
    func async(qos: DispatchQoS, closure: @escaping () -> Void) {
        async(group: nil, qos: qos, flags: [], execute: closure)
    }
}
