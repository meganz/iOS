import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGAPreference

@MainActor
final class RecentsWidgetViewModel: ObservableObject {

    @Published private(set) var state: RecentWidgetUseCaseState = .hidden

    @PreferenceWrapper(key: PreferenceKeyEntity.showRecents, defaultValue: true, useCase: PreferenceUseCase.default)
    private var showRecentsPreference: Bool

    private let recentsActionsStatesUseCase: any RecentsActionsStatesUseCaseProtocol
    private let clearRecentActionHistoryUseCase: any ClearRecentActionHistoryUseCaseProtocol
    
    convenience init() {
        self.init(
            recentsActionsStatesUseCase: RecentsActionsStatesUseCase(),
            clearRecentActionHistoryUseCase: ClearRecentActionHistoryUseCase()
        )
    }
    
    package init(
        recentsActionsStatesUseCase: some RecentsActionsStatesUseCaseProtocol,
        clearRecentActionHistoryUseCase: some ClearRecentActionHistoryUseCaseProtocol
    ) {
        self.recentsActionsStatesUseCase = recentsActionsStatesUseCase
        self.clearRecentActionHistoryUseCase = clearRecentActionHistoryUseCase
    }

    func onTask() async {
        await refreshState()
        await observeRecentBucketUpdates()
    }

    func didTapShowActivityButton() async {
        showRecentsPreference = true
        await refreshState()
    }

    func didTapRetryButton() async {
        state = .loading
        await refreshState()
    }

    func hideRecentActivity() async {
        showRecentsPreference = false
        await refreshState()
    }
    
    func clearRecentActivity() async -> String? {
        do {
            try await clearRecentActionHistoryUseCase.clearRecentActionHistory()
            await refreshState()
            return Strings.Localizable.Home.Recent.ClearRecentActivity.Snackbar.message
        } catch {
            return nil
        }
    }

    private func observeRecentBucketUpdates() async {
        for await _ in recentsActionsStatesUseCase.states {
            await refreshState()
        }
    }

    private func refreshState() async {
        state = await recentsActionsStatesUseCase.getLatestBucketState()
    }
}

private extension RecentWidgetUseCaseState {
    var actionButtonTitle: String {
        switch self {
        case .empty, .nonEmpty:
            Strings.Localizable.upload
        case .hidden:
            Strings.Localizable.Recents.EmptyState.ActivityHidden.button
        case .error:
            Strings.Localizable.retry
        case .loading:
            ""
        }
    }
}
