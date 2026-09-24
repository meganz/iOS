import Combine
import MEGAAppPresentation
import MEGADomain
import MEGARepo
import Video

@MainActor
final class VideoPlaylistContentContainerViewModel: ObservableObject {
    
    @Published var sortOrder: SortOrderEntity = .defaultAsc
    @Published private(set) var isNetworkOffline = false
    
    private(set) var cancellables: Set<AnyCancellable> = []
    
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let overDiskQuotaChecker: any OverDiskQuotaChecking
    private let offlineActionGuard: any OfflineActionGuarding
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private var networkConnectivityTask: Task<Void, Never>?
    
    private(set) var sharedUIState = VideoPlaylistContentSharedUIState()
    
    init(sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
         overDiskQuotaChecker: some OverDiskQuotaChecking,
         offlineActionGuard: some OfflineActionGuarding = OfflineActionGuard(
            isNewOfflineModeEnabled: DIContainer.featureFlagProvider.isNewOfflineModeEnabled
         ),
         networkMonitorUseCase: some NetworkMonitorUseCaseProtocol = NetworkMonitorUseCase(
            repo: NetworkMonitorRepository.newRepo
         )) {
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.overDiskQuotaChecker = overDiskQuotaChecker
        self.offlineActionGuard = offlineActionGuard
        self.networkMonitorUseCase = networkMonitorUseCase
        
        monitorSortOrderChanged()
        monitorNetworkConnectivity()
    }
    
    deinit {
        networkConnectivityTask?.cancel()
    }
    
    private func monitorNetworkConnectivity() {
        guard DIContainer.featureFlagProvider.isNewOfflineModeEnabled else { return }
        networkConnectivityTask = Task { [weak self, networkMonitorUseCase] in
            let connectionSequence = networkMonitorUseCase
                .connectionSequence
                .prepend(networkMonitorUseCase.isConnected())
                .removeDuplicates()
            for await isConnected in connectionSequence {
                guard let self else { return }
                isNetworkOffline = !isConnected
            }
        }
    }
    
    private func monitorSortOrderChanged() {
        sortOrderChangedSequence()
            .receive(on: DispatchQueue.main)
            .assign(to: \.sortOrder, on: self)
            .store(in: &cancellables)
    }
    
    private func sortOrderChangedSequence() -> AnyPublisher<SortOrderEntity, Never> {
        let defaultSortOrder = SortOrderEntity.modificationAsc
        return sortOrderPreferenceUseCase.monitorSortOrder(for: . videoPlaylistContent)
            .map { [weak self] sortOrder in
                guard let self else {
                    return defaultSortOrder
                }
                return doesSupport(sortOrder) ? sortOrder : defaultSortOrder
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private func doesSupport(_ sortOrder: SortOrderEntity) -> Bool {
        PlaylistContentSupportedSortOrderPolicy.supportedSortOrders.contains(sortOrder)
    }
    
    func didSelectSortMenu(sortOrder: SortOrderEntity) {
        guard doesSupport(sortOrder) else {
            return
        }
        sortOrderPreferenceUseCase.save(sortOrder: sortOrder, for: .videoPlaylistContent)
    }
    
    func didSelectMenuAction(_ action: DisplayActionEntity) {
        guard !action.requiresConnection || offlineActionGuard.allowsActionRequiringConnection() else {
            return
        }
        guard !(action == .newPlaylist && showOverDiskQuotaIfNeeded()) else {
            return
        }
        sharedUIState.selectedDisplayActionEntity = action
    }
    
    func didSelectQuickAction(_ action: QuickActionEntity) {
        guard !action.requiresConnection || offlineActionGuard.allowsActionRequiringConnection() else {
            return
        }
        guard !([QuickActionEntity.download, .shareLink, .manageLink,
                 .removeLink, .rename, .saveToPhotos].contains(action) &&
                showOverDiskQuotaIfNeeded()) else {
            return
        }
        sharedUIState.selectedQuickActionEntity = action
    }
    
    func didSelectVideoPlaylistAction(_ action: VideoPlaylistActionEntity) {
        guard offlineActionGuard.allowsActionRequiringConnection() else { return }
        guard !showOverDiskQuotaIfNeeded() else { return }
        sharedUIState.selectedVideoPlaylistActionEntity = action
    }
    
    func showOverDiskQuotaIfNeeded() -> Bool {
        overDiskQuotaChecker.showOverDiskQuotaIfNeeded()
    }
}
