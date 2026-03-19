import Foundation
import MEGADomain
import MEGAL10n
import MEGAPreference

@MainActor
final class RecentsWidgetViewModel: ObservableObject {
    enum State {
        case empty
        case nonEmpty([DailyRecentActionBucketGroup])
        case hidden
        
        var actionButtonTitle: String {
            switch self {
            case .empty, .nonEmpty:
                Strings.Localizable.upload
            case .hidden:
                Strings.Localizable.Recents.EmptyState.ActivityHidden.button
            }
        }
    }

    @Published private(set) var state: State = .hidden
    
    @PreferenceWrapper(key: PreferenceKeyEntity.showRecents, defaultValue: true, useCase: PreferenceUseCase.default)
    private var showRecentsPreference: Bool
    
    private let homeRecentsWidgetUseCase: any HomeRecentsWidgetUseCaseProtocol

    convenience init() {
        self.init(homeRecentsWidgetUseCase: HomeRecentsWidgetUseCase())
    }
    
    package init(homeRecentsWidgetUseCase: some HomeRecentsWidgetUseCaseProtocol) {
        self.homeRecentsWidgetUseCase = homeRecentsWidgetUseCase
    }

    func onTask() async {
        await refreshState()
    }

    func didTapShowActivityButton() async {
        showRecentsPreference = true
        await refreshState()
    }

    func didTapMoreButton() {
        // Waiting for product/design decision for the top-right menu action.
    }

    private func refreshState() async {
        if !showRecentsPreference {
            state = .hidden
            return
        }

        do throws(HomeRecentWidgetsErrorEntity) {
            let bucketGroups = try await homeRecentsWidgetUseCase.recentBuckets()
            state = bucketGroups.isEmpty ? .empty : .nonEmpty(bucketGroups)
        } catch {
            switch error {
            case .cancellation:
                break
            }
        }
    }
}
