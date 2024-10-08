@preconcurrency import Combine
import Foundation
import MEGASwift

public final class Debouncer: NSObject, Sendable {
    public typealias Action = () -> Void
    private let subject = PassthroughSubject<Action, Never>()
    private let scheduler = DispatchQueue(label: "nz.mega.MEGAFoundation.Debouncer.scheduler")
    
    private let cancellable = Atomic<AnyCancellable?>(wrappedValue: nil)
    
    public init(delay: TimeInterval, dispatchQueue: DispatchQueue = .main) {
        super.init()
        cancellable.mutate {
            $0 = subject
                .debounce(for: .seconds(delay), scheduler: scheduler)
                .receive(on: dispatchQueue)
                .sink { $0() }
        }
    }
    
    public func start(action: @escaping Action) {
        subject.send(action)
    }

    public func cancel() {
        cancellable.wrappedValue?.cancel()
    }
}
