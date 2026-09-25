import Combine
import Foundation
import MEGADomain
import MEGASwift

@MainActor
final class ViewedLinksWidgetViewModel: ObservableObject {
    enum State {
        case loading
        case loaded([ViewedLinkWidgetRowModel])
        case empty
    }

    @Published private(set) var state: State = .loading

    private let viewedLinksUseCase: any ViewedLinksUseCaseProtocol
    private let limit: Int

    init(
        viewedLinksUseCase: some ViewedLinksUseCaseProtocol,
        limit: Int = 4
    ) {
        self.viewedLinksUseCase = viewedLinksUseCase
        self.limit = limit
    }

    func onTask() async {
        for await _ in viewedLinksUseCase.changesSignalSequence().prepend(()) {
            await reload()
        }
    }

    private func reload() async {
        let links: [ViewedLinkWidgetRowModel]
        do throws(ViewedLinkErrorEntity) {
            links = try await viewedLinksUseCase.topViewedLinks(limit: limit)
                .map(\.toWidgetRowModel)
        } catch {
            handleFetchFailure(error)
            return
        }
        guard !Task.isCancelled else { return }
        state = links.isNotEmpty ? .loaded(links) : .empty
    }

    private func handleFetchFailure(_ error: ViewedLinkErrorEntity) {
        switch error {
        case .cancelled:
            // The fetch operation was cancelled, do nothing
            return
        case .notFound, .storeOperationFailed:
            state = .empty
        }
    }
}
