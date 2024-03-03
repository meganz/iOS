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
        
        enum NavigationBarCommand {
            case toggleEditing
            case refreshContextMenu
        }
    }
    
    var invokeCommand: ((Command) -> Void)?
    
    var isSelectHidden = false
    var isEditing = false
    
    private(set) var syncModel = VideoRevampSyncModel()
    
    private var subscriptions = Set<AnyCancellable>()
    
    private let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    
    init(
        sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol = SortOrderPreferenceUseCase(preferenceUseCase: PreferenceUseCase.default, sortOrderPreferenceRepository: SortOrderPreferenceRepository.newRepo)
    ) {
        self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
    }
    
    func dispatch(_ action: Action) {
        switch action {
        case .onViewDidLoad:
            loadSortOrderType()
            monitorSortOrderSubscription()
        case .navigationBarAction(.didReceivedDisplayMenuAction(let action)):
            switch action {
            case .select:
                isEditing = true
                invokeCommand?(.navigationBarCommand(.toggleEditing))
            default:
                break
            }
        case .navigationBarAction(.didSelectSortMenuAction(let sortOrderType)):
            sortOrderPreferenceUseCase.save(sortOrder: sortOrderType.toSortOrderEntity(), for: .homeVideos)
        case .navigationBarAction(.didTapSelectAll):
            break
        case .navigationBarAction(.didTapCancel):
            self.isEditing = false
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
}
