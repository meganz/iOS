import Combine
import MEGADomain
import Video

@MainActor
final class VideoPlaylistContentContainerViewModel: ObservableObject {
    
    @Published var sortOrder: SortOrderEntity = .defaultAsc
    
    private(set) var cancellables: Set<AnyCancellable> = []
    
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private let overDiskQuotaChecker: any OverDiskQuotaChecking
    
    private(set) var sharedUIState = VideoPlaylistContentSharedUIState()
    
    init(sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
         overDiskQuotaChecker: some OverDiskQuotaChecking) {
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.overDiskQuotaChecker = overDiskQuotaChecker
        
        monitorSortOrderChanged()
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
        guard !(action == .newPlaylist && showOverDiskQuotaIfNeeded()) else {
            return
        }
        sharedUIState.selectedDisplayActionEntity = action
    }
    
    func didSelectQuickAction(_ action: QuickActionEntity) {
        guard !([QuickActionEntity.download, .shareLink, .manageLink,
                 .removeLink, .rename, .saveToPhotos].contains(action) &&
                showOverDiskQuotaIfNeeded()) else {
            return
        }
        sharedUIState.selectedQuickActionEntity = action
    }
    
    func didSelectVideoPlaylistAction(_ action: VideoPlaylistActionEntity) {
        guard !showOverDiskQuotaIfNeeded() else { return }
        sharedUIState.selectedVideoPlaylistActionEntity = action
    }
    
    func showOverDiskQuotaIfNeeded() -> Bool {
        overDiskQuotaChecker.showOverDiskQuotaIfNeeded()
    }
}
