import MEGADomain
import MEGAPresentation

final class VideoRevampTabContainerViewModel: ViewModelType {
    
    enum Action: ActionType {
        case onViewDidLoad
        case navigationBarAction(NavigationBarAction)
        
        enum NavigationBarAction {
            case didReceivedDisplayMenuAction(action: DisplayActionEntity)
            case didSelectSortMenuAction(sortType: SortOrderType)
            case didTapSelectAll
            case didTapCancel
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
    
    var isFilterActive = false
    var isSelectHidden = false
    var isEditing = false
    
    private(set) var videoRevampSortOrderType: SortOrderType = .none
    
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
        case .navigationBarAction(.didReceivedDisplayMenuAction(let action)):
            switch action {
            case .select:
                isEditing = true
                invokeCommand?(.navigationBarCommand(.toggleEditing))
            case .sort:
                videoRevampSortOrderType = sortOrderPreferenceUseCase.sortOrder(for: .homeVideos).toSortOrderType()
            case .filter:
                // router.showFilter()
                break
            default:
                break
            }
        case .navigationBarAction(.didSelectSortMenuAction(let sortOrderType)):
            sortOrderPreferenceUseCase.save(sortOrder: sortOrderType.toSortOrderEntity(), for: .homeVideos)
            videoRevampSortOrderType = sortOrderType
            invokeCommand?(.navigationBarCommand(.refreshContextMenu))
        case .navigationBarAction(.didTapSelectAll):
            break
        case .navigationBarAction(.didTapCancel):
            self.isEditing = false
        }
    }
    
    private func loadSortOrderType() {
        videoRevampSortOrderType = sortOrderPreferenceUseCase
            .sortOrder(for: .homeVideos)
            .toSortOrderType()
    }
}
