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

    convenience init() {
        self.init(
            recentsActionsStatesUseCase: RecentsActionsStatesUseCase()
        )
    }
    
    package init(
        recentsActionsStatesUseCase: some RecentsActionsStatesUseCaseProtocol
    ) {
        self.recentsActionsStatesUseCase = recentsActionsStatesUseCase
    }

    func onTask() async {
        await refreshState()
        await observeRecentBucketUpdates()
    }

    func didTapShowActivityButton() async {
        showRecentsPreference = true
        await refreshState()
    }

    func didTapMoreButton() {
        // Waiting for product/design decision for the top-right menu action.
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
        }
    }
}
