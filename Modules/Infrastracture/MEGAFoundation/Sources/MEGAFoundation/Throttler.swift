@preconcurrency import Combine
import Foundation

public final class Throttler: Sendable {
    public typealias Action = () -> Void
    private let subject = PassthroughSubject<Action, Never>()
    private let cancellable: AnyCancellable
    
    public init(timeInterval: TimeInterval, dispatchQueue: DispatchQueue = .main) {
        cancellable = subject
            .throttle(for: .seconds(timeInterval), scheduler: RunLoop.main, latest: true)
            .receive(on: dispatchQueue)
            .sink { $0() }
    }
    
    public func start(action: @escaping () -> Void) {
        subject.send(action)
    }
}
