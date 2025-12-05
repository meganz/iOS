import MEGASwift
import Search

protocol SearchResultsEmptyStateProviding: Sendable {
    var emptyStateSequence: AnyAsyncSequence<Bool> { get }
}

/// Wrapper around SearchResultsViewModel to tunnel its `itemCountSequence` from main actor to background actor
struct SearchResultsEmptyStateProvider: SearchResultsEmptyStateProviding {
    private weak var viewModel: SearchResultsViewModel?

    init(viewModel: SearchResultsViewModel) {
        self.viewModel = viewModel
    }

    var emptyStateSequence: AnyAsyncSequence<Bool> {
        guard let viewModel else { return EmptyAsyncSequence<Bool>().eraseToAnyAsyncSequence() }
        let (stream, continuation) = AsyncStream
            .makeStream(of: Bool.self, bufferingPolicy: .bufferingNewest(1))

        let task = Task {
            let itemCountSequence = await viewModel.itemCountSequence
            for await isEmpty in itemCountSequence.map({ $0 == 0 }) {
                continuation.yield(isEmpty)
            }
            continuation.finish()
        }
        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
        return stream.eraseToAnyAsyncSequence()
    }
}
