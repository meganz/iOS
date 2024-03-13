import Combine
import MEGADomain
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
        }
    }
    
    enum Command: CommandType, Equatable { 
        case navigationBarCommand(NavigationBarCommand)
        case searchBarCommand(SearchBarCommand)
        
        enum NavigationBarCommand: Equatable {
            case toggleEditing
            case refreshContextMenu
            case renderNavigationTitle(NavigationTitleType)
            
            enum NavigationTitleType: Equatable {
                case videos
                case selectItems
                case selectItemsWithCount(Int)
            }
        }
        
        enum SearchBarCommand: Equatable {
            case hideSearchBar
            case reshowSearchBar
        }
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    var isSelectHidden = false
    
    private(set) var syncModel = VideoRevampSyncModel()
    
    private var subscriptions = Set<AnyCancellable>()
    
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    private(set) var videoSelection: VideoSelection
    
    init(
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = SortOrderPreferenceUseCase(preferenceUseCase: PreferenceUseCase.default, sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo),
        videoSelection: VideoSelection
    ) {
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        self.videoSelection = videoSelection
        
        listenToEditingMode()
        listenToVideoSelection()
    }
    
    func dispatch(_ action: Action) {
        switch action {
        case .onViewDidLoad:
            invokeCommand?(.navigationBarCommand(.renderNavigationTitle(.videos)))
            loadSortOrderType()
            monitorSortOrderSubscription()
        case .navigationBarAction(.didReceivedDisplayMenuAction(let action)):
            switch action {
            case .select:
                syncModel.editMode = .active
                invokeCommand?(.navigationBarCommand(.toggleEditing))
                invokeCommand?(.searchBarCommand(.hideSearchBar))
                syncModel.searchText.removeAll()
            default:
                break
            }
        case .navigationBarAction(.didSelectSortMenuAction(let sortOrderType)):
            sortOrderPreferenceUseCase.save(sortOrder: sortOrderType.toSortOrderEntity(), for: .homeVideos)
        case .navigationBarAction(.didTapSelectAll):
            syncModel.isAllSelected = !syncModel.isAllSelected
        case .navigationBarAction(.didTapCancel):
            syncModel.editMode = .inactive
            syncModel.searchText.removeAll()
            invokeCommand?(.searchBarCommand(.reshowSearchBar))
        case .searchBarAction(.updateSearchResults(let searchText)):
            syncModel.searchText = searchText
        case .searchBarAction(.cancel):
            syncModel.searchText = ""
        }
    }
    
    private func loadSortOrderType() {
        syncModel.videoRevampSortOrderType = sortOrderPreferenceUseCase
            .sortOrder(for: .homeVideos)
    }
    
    private func monitorSortOrderSubscription() {
        sortOrderPreferenceUseCase.monitorSortOrder(for: .homeVideos)
            .map { $0.toSortOrderType().toSortOrderEntity() }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.syncModel.videoRevampSortOrderType = $0
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
                 if isEditing {
                     if videos.isEmpty {
                         self?.invokeCommand?(.navigationBarCommand(.renderNavigationTitle(.selectItems)))
                     } else {
                         self?.invokeCommand?(.navigationBarCommand(.renderNavigationTitle(.selectItemsWithCount(videos.count))))
                     }
                 } else {
                     self?.invokeCommand?(.navigationBarCommand(.renderNavigationTitle(.videos)))
                 }
             }
             .store(in: &subscriptions)
     }
}
