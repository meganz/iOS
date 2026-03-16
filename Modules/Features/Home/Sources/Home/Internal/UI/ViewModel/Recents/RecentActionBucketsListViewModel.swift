import Combine
import MEGADomain
import MEGAL10n
import MEGAPreference
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

    init(
        recentActionBucketsListUseCase: some RecentActionBucketsListUseCaseProtocol = RecentActionBucketsListUseCase(),
        clearRecentActionHistoryUseCase: some ClearRecentActionHistoryUseCaseProtocol = ClearRecentActionHistoryUseCase()
    ) {
        self.recentActionBucketsListUseCase = recentActionBucketsListUseCase
        self.clearRecentActionHistoryUseCase = clearRecentActionHistoryUseCase
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
