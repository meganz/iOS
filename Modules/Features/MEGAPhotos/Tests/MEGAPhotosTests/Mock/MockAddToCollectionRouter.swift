@testable import MEGAPhotos
import MEGASwift
import UIKit

final class MockAddToCollectionRouter: AddToCollectionRouting {
    public enum Invocation: Sendable, Equatable {
        case dismiss
        case showSnackBar(message: String)
    }
    public var invocationSequence: AnyAsyncSequence<Invocation> {
        invocationStream.eraseToAnyAsyncSequence()
    }
    private let invocationStream: AsyncStream<Invocation>
    private let invocationContinuation: AsyncStream<Invocation>.Continuation
    
    init() {
        (invocationStream, invocationContinuation) = AsyncStream.makeStream(of: Invocation.self)
    }
    
    func build() -> UIViewController {
        UIViewController()
    }
    
    func start() {
        
    }
    
    func dismiss(completion: (() -> Void)?) {
        invocationContinuation.yield(.dismiss)
        completion?()
    }
    
    func showSnackBar(message: String) {
        invocationContinuation.yield(.showSnackBar(message: message))
    }
}
