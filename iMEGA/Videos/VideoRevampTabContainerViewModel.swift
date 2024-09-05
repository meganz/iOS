import Combine
import MEGADomain
import MEGAL10n
import MEGAPresentation
import Video

final class VideoRevampTabContainerViewModel: ViewModelType {
    
    enum Action: ActionType {
        case onViewDidLoad
        case navigationBarAction(NavigationBarAction)
        case searchBarAction(SearchBarAction)
        
        enum NavigationBarAction {
            case didReceivedDisplayMenuAction(action: DisplayActionEntity)
            case didSelectSortMenuAction(sortType: SortOrderType)
            case didTapSelectAll
            case didTapCancel
        }
        
        enum SearchBarAction {
            case updateSearchResults(searchText: String)
            case cancel
            case searchBarTextDidEndEditing
            case becomeActive
        }
    }
    
    enum Command: CommandType, Equatable { 
        case navigationBarCommand(NavigationBarActionCommand)
        case searchBarCommand(SearchBarCommand)
        
        enum NavigationBarActionCommand: Equatable {
            case toggleEditing
            case refreshContextMenu
            case renderNavigationTitle(String)
        }
        
        enum SearchBarCommand: Equatable {
            case hideSearchBar
            case reshowSearchBar
        }
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    var isSelectHidden = false
    
    private(set) var syncModel: VideoRevampSyncModel
    
    private var subscriptions = Set<AnyCancellable>()
    
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private(set) var videoSelection: VideoSelection
    
    init(
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = SortOrderPreferenceUseCase(preferenceUseCase: PreferenceUseCase.default, sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo),
        videoSelection: VideoSelection,
        syncModel: VideoRevampSyncModel
    ) {
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.videoSelection = videoSelection
        self.syncModel = syncModel
        
        listenToEditingMode()
        listenToVideoSelection()
    }
    
    func dispatch(_ action: Action) {
        switch action {
        case .onViewDidLoad:
            invokeCommand?(.navigationBarCommand(.renderNavigationTitle(Strings.Localizable.Videos.Navigationbar.title)))
            loadSortOrderType()
            monitorSortOrderSubscription()
        case .navigationBarAction(.didReceivedDisplayMenuAction(let action)):
            switch action {
            case .select:
                syncModel.editMode = .active
                invokeCommand?(.navigationBarCommand(.toggleEditing))
                invokeCommand?(.searchBarCommand(.hideSearchBar))
                syncModel.searchText.removeAll()
            case .newPlaylist:
                syncModel.shouldShowAddNewPlaylistAlert = true
            default:
                break
            }
        case .navigationBarAction(.didSelectSortMenuAction(let sortOrderType)):
            let keyEntity: SortOrderPreferenceKeyEntity = syncModel.currentTab == .all ? .homeVideos : .homeVideoPlaylists
            let sortOrderEntity = sortOrderEntity(from: sortOrderType, for: syncModel.currentTab)
            sortOrderPreferenceUseCase.save(sortOrder: sortOrderEntity, for: keyEntity)
        case .navigationBarAction(.didTapSelectAll):
            syncModel.isAllSelected = !syncModel.isAllSelected
        case .navigationBarAction(.didTapCancel):
            syncModel.editMode = .inactive
            syncModel.isSearchActive = false
            syncModel.searchText.removeAll()
            invokeCommand?(.searchBarCommand(.reshowSearchBar))
        case .searchBarAction(.updateSearchResults(let searchText)):
            syncModel.searchText = searchText
        case .searchBarAction(.cancel):
            syncModel.searchText = ""
            syncModel.isSearchActive = false
        case .searchBarAction(.searchBarTextDidEndEditing):
            if syncModel.isSearchActive && syncModel.searchText.isNotEmpty {
                return
            }
            syncModel.searchText = ""
            syncModel.isSearchActive = false
        case .searchBarAction(.becomeActive):
            syncModel.isSearchActive = true
        }
    }
    
    private func sortOrderEntity(from sortOrderType: SortOrderType, for currentTab: VideosTab) -> SortOrderEntity {
        switch syncModel.currentTab {
        case .all:
            sortOrderType.toSortOrderEntity()
        case .playlist:
            sortOrderType.toVideoPlaylistSortOrderEntity()
        }
    }
    
    private func loadSortOrderType() {
        syncModel.videoRevampSortOrderType = sortOrderPreferenceUseCase
            .sortOrder(for: .homeVideos)
        
        syncModel.videoRevampVideoPlaylistsSortOrderType = sortOrderPreferenceUseCase
            .sortOrder(for: .homeVideoPlaylists)
    }
    
    private func monitorSortOrderSubscription() {
        sortOrderPreferenceUseCase.monitorSortOrder(for: .homeVideos)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.syncModel.videoRevampSortOrderType = $0
                self?.reloadContextMenu()
            }
            .store(in: &subscriptions)
        
        sortOrderPreferenceUseCase.monitorSortOrder(for: .homeVideoPlaylists)
            .map { $0.toVideoPlaylistSortOrderEntity() }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.syncModel.videoRevampVideoPlaylistsSortOrderType = $0
                self?.reloadContextMenu()
            }
            .store(in: &subscriptions)
    }
    
    private func reloadContextMenu() {
        invokeCommand?(.navigationBarCommand(.refreshContextMenu))
    }
    
    private func listenToEditingMode() {
        syncModel.$editMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] editMode in
                self?.videoSelection.editMode = editMode
            }
            .store(in: &subscriptions)
    }
    
    private func listenToVideoSelection() {
        let editModePublisher = videoSelection.$editMode.map { $0.isEditing }
        let videosPublisher = videoSelection.$videos
        
        Publishers.CombineLatest(editModePublisher, videosPublisher)
            .receive(on: DispatchQueue.main)
            .removeDuplicates(by: { $0 == $1 })
            .sink { [weak self] isEditing, videos in
                var title = ""
                if isEditing {
                    if videos.isEmpty {
                        title = Strings.Localizable.selectTitle
                    } else {
                        title = Strings.Localizable.General.Format.itemsSelected(videos.count)
                    }
                } else {
                    title = Strings.Localizable.Videos.Navigationbar.title
                }
                self?.invokeCommand?(.navigationBarCommand(.renderNavigationTitle(title)))
            }
            .store(in: &subscriptions)
    }
}
