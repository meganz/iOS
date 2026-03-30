@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGASwift

protocol RecentActionBucketsListUpdatesUseCaseProtocol: Sendable {
    var updates: AnyAsyncSequence<Void> { get }
}

struct RecentActionBucketsListUpdatesUseCase: RecentActionBucketsListUpdatesUseCaseProtocol {
    let recentNodesUseCase: any RecentNodesUseCaseProtocol

    var updates: AnyAsyncSequence<Void> {
        AsyncStream { continuation in
            let subject = PassthroughSubject<Void, Never>()

            // `.throttle()` is needed because recentNodesUseCase can rapidly emit updates in a short time (e.g: When
            // user uploads loads of small text files, sdk will callbacks dozens of time in a second) which can
            // result in rapid UI updates which is not ideal for performance.
            let cancellable = subject
                .throttle(for: .seconds(0.5), scheduler: DispatchQueue.main, latest: true)
                .sink { continuation.yield(()) }

            let task = Task {
                for await _ in recentNodesUseCase.recentActionBucketsUpdates {
                    subject.send(())
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
                cancellable.cancel()
            }
        }.eraseToAnyAsyncSequence()
    }
}
