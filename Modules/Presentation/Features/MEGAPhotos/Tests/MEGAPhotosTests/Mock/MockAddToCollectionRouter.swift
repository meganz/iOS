@testable import MEGAPhotos
import MEGASwift
import UIKit

class MockAddToCollectionRouter: AddToCollectionRouting {
    public enum Invocation: Sendable, Equatable {
        case showSnackBarOnDismiss(message: String)
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
    
    func showSnackBarOnDismiss(message: String) {
        invocationContinuation.yield(.showSnackBarOnDismiss(message: message))
    }
}
