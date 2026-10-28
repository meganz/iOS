import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
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
    private let tracker: any AnalyticsTracking

    init(
        viewedLinksUseCase: some ViewedLinksUseCaseProtocol,
        limit: Int = 4,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.viewedLinksUseCase = viewedLinksUseCase
        self.limit = limit
        self.tracker = tracker
    }

    func didTapLink(_ row: ViewedLinkWidgetRowModel) {
        if row.isFolder {
            tracker.trackAnalyticsEvent(with: ViewedLinksWidgetFolderLinkItemSelectedEvent())
        } else {
            tracker.trackAnalyticsEvent(with: ViewedLinksWidgetFileLinkItemSelectedEvent())
        }
    }

    func didTapViewAll() {
        tracker.trackAnalyticsEvent(with: ViewedLinksViewAllButtonPressedEvent())
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
