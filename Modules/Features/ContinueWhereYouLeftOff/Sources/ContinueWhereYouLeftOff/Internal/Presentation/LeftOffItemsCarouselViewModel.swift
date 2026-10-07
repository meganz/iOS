import AsyncAlgorithms
import Foundation
import MEGADomain
import MEGASwift

@MainActor
@Observable
final class LeftOffItemsCarouselViewModel {
    enum State: Equatable {
        case loading
        case loaded(items: [LeftOffItemWidgetCardModel], hasMore: Bool, isLoadingMore: Bool)
        case empty
    }

    static let initialPageSize = 8

    private(set) var state: State = .loading

    private let leftOffItemsUseCase: any LeftOffItemsUseCaseProtocol
    private let debounceInterval: Duration
    private var pageSize = LeftOffItemsCarouselViewModel.initialPageSize

    init(
        leftOffItemsUseCase: some LeftOffItemsUseCaseProtocol,
        debounceInterval: Duration = .milliseconds(300)
    ) {
        self.leftOffItemsUseCase = leftOffItemsUseCase
        self.debounceInterval = debounceInterval
    }

    func onTask() async {
        // need to debounce because `changesSignalSequence` can rapidly fire signals (e.g: Uploading multiple
        // small files
        for await _ in leftOffItemsUseCase.changesSignalSequence()
            .debounce(for: debounceInterval)
            .prepend(()) {
            await reload()
        }
    }

    func loadMore() async {
        guard case .loaded(let items, let hasMore, _) = state, hasMore else { return }
        state = .loaded(items: items, hasMore: hasMore, isLoadingMore: true)
        pageSize += Self.initialPageSize
        await reload()
    }

    private func reload() async {
        let limit = pageSize
        let resolvedItems: [ResolvedLeftOffItemEntity]
        do throws(LeftOffItemErrorEntity) {
            // Need to request for `limit + 1` to figure out if there are still more left off items
            // So we can display the "More" button on UI
            resolvedItems = try await leftOffItemsUseCase.topItems(limit: limit + 1)
        } catch {
            handleFetchFailure(error, limit: limit)
            return
        }
        // Many `reload()` calls can be triggered simultaneously. E.g: user triggers `loadMore()`,
        // and then `changesSignalSequence()` triggers reload() at the same time.
        // The former increase the `pageSize`, but the latter doesn't. This could lead to the bug
        // where the result of the former lands first (containing more items), then get overwritten
        // by the latter (containing fewer items).
        // In this case we prefer to use the results from the loadMore() and drop the other
        // which can be done by checking `limit == pageSize`
        guard !Task.isCancelled, limit == pageSize else { return }
        let cards = resolvedItems.prefix(limit).map(LeftOffItemWidgetCardModel.init)
        let newState: State = cards.isEmpty
            ? .empty
            : .loaded(items: cards, hasMore: resolvedItems.count > limit, isLoadingMore: false)
        if newState != state {
            state = newState
        }
    }

    private func handleFetchFailure(_ error: LeftOffItemErrorEntity, limit: Int) {
        switch error {
        case .cancelled:
            return
        case .persistenceFailure:
            guard limit == pageSize else { return }
            switch state {
            case .loading:
                state = .empty
            case .empty:
                break
            case .loaded(let items, let hasMore, _):
                let newState = State.loaded(items: items, hasMore: hasMore, isLoadingMore: false)
                if newState != state {
                    state = newState
                }
            }
        }
    }
}
