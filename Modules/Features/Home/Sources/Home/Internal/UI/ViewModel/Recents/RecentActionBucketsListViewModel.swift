@preconcurrency import Combine
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGASwift
import MEGASwiftUI

@MainActor
final class RecentActionBucketsListViewModel: ObservableObject {
    enum ViewState {
        case loading
        case results([RecentActionBucketSection])
    }

    @Published var viewState: ViewState = .loading
    @Published var isConfirmingClearRecentActivity: Bool = false

    private(set) var recentActivityHiddenSnackBar: SnackBar?
    private(set) var recentActivityClearedSnackBar: SnackBar?

    @PreferenceWrapper(key: PreferenceKeyEntity.showRecents, defaultValue: true, useCase: PreferenceUseCase.default)
    private var showRecentActivityEnabled: Bool

    private let recentActionBucketsListUseCase: any RecentActionBucketsListUseCaseProtocol
    private let clearRecentActionHistoryUseCase: any ClearRecentActionHistoryUseCaseProtocol
    private let recentActionBucketSectionMapper = RecentActionBucketSectionMapper()
    private let recentActionBucketsListUpdatesUseCase: any RecentActionBucketsListUpdatesUseCaseProtocol

    init(
        recentActionBucketsListUseCase: some RecentActionBucketsListUseCaseProtocol = RecentActionBucketsListUseCase(),
        clearRecentActionHistoryUseCase: some ClearRecentActionHistoryUseCaseProtocol = ClearRecentActionHistoryUseCase(),
        recentActionBucketsListUpdatesUseCase: some RecentActionBucketsListUpdatesUseCaseProtocol = RecentActionBucketsListUpdatesUseCase(
            recentNodesUseCase: RecentNodesUseCase(
                recentNodesRepository: RecentNodesRepository.newRepo,
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(repo: UserAttributeRepository.newRepo),
                userUpdateRepository: UserUpdateRepository.newRepo,
                requestStatesRepository: RequestStatesRepository.newRepo,
                nodeRepository: NodeRepository.newRepo
            )
        )
    ) {
        self.recentActionBucketsListUseCase = recentActionBucketsListUseCase
        self.clearRecentActionHistoryUseCase = clearRecentActionHistoryUseCase
        self.recentActionBucketsListUpdatesUseCase = recentActionBucketsListUpdatesUseCase
    }
    
    func loadRecentActionBuckets() async {
        do throws(RecentActionBucketsListErrorEntity) {
            let bucketGroups = try await recentActionBucketsListUseCase.recentActionsBuckets()
            viewState = .results(recentActionBucketSectionMapper.map(bucketGroups: bucketGroups))
        } catch {
            switch error {
            case .cancellation:
                // to be confirmed.
                viewState = .results([])
            }
        }
    }

    func observeRecentBucketUpdates() async {
        for await _ in recentActionBucketsListUpdatesUseCase.updates {
            await loadRecentActionBuckets()
        }
    }

    func hideRecentActivity() {
        showRecentActivityEnabled = false
        recentActivityHiddenSnackBar = SnackBar(message: Strings.Localizable.Home.Recent.HideRecentActivity.Snackbar.message)
    }
    
    func confirmClearRecentActivity() {
        isConfirmingClearRecentActivity = true
    }
    
    func clearRecentActivity() async {
        do {
            try await clearRecentActionHistoryUseCase.clearRecentActionHistory()
            recentActivityClearedSnackBar = SnackBar(message: Strings.Localizable.Home.Recent.ClearRecentActivity.Snackbar.message)
        } catch {}
    }
}
