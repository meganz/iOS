import AsyncAlgorithms
import MEGASwift
import Search

protocol SearchResultsViewStateProviding: Sendable {
    var isEditingOrEmpty: AnyAsyncSequence<Bool> { get }
}

/// Wrapper around SearchResultsViewModel to tunnel its `itemCountSequence` from main actor to background actor
struct SearchResultsViewStateProvider: SearchResultsViewStateProviding {
    private weak var viewModel: SearchResultsViewModel?

    init(viewModel: SearchResultsViewModel) {
        self.viewModel = viewModel
    }

    var isEditingOrEmpty: AnyAsyncSequence<Bool> {
        guard let viewModel else { return EmptyAsyncSequence<Bool>().eraseToAnyAsyncSequence() }
        let (stream, continuation) = AsyncStream
            .makeStream(of: Bool.self, bufferingPolicy: .bufferingNewest(1))

        let task = Task { @MainActor in
            let emptyItemSequence = viewModel.itemCountSequence.map { $0 == 0 }
                .eraseToAnyAsyncSequence()
            let editingSequence = viewModel.$editing.values.eraseToAnyAsyncSequence()

            let resultSequence = combineLatest(emptyItemSequence, editingSequence)
                .map { $0 || $1 }

            for await isEmptyOrEditing in resultSequence {
                continuation.yield(isEmptyOrEditing)
            }
            continuation.finish()
        }
        continuation.onTermination = { @Sendable _ in
            task.cancel()
        }
        return stream.eraseToAnyAsyncSequence()
    }
}
