import Combine
import MEGADomain
import Search

@MainActor
final class FolderLinkResultsContainerViewModel: ObservableObject {
    struct Dependency {
        let handle: HandleEntity
        let viewModeUseCase: any FolderLinkViewModeUseCaseProtocol
        
        init(handle: HandleEntity, viewModeUseCase: any FolderLinkViewModeUseCaseProtocol) {
            self.handle = handle
            self.viewModeUseCase = viewModeUseCase
        }
        
        init(handle: HandleEntity) {
            self.init(
                handle: handle,
                viewModeUseCase: FolderLinkViewModeUseCase()
            )
        }
    }
    
    /// Holds the source of truth for the view mode.
    /// It is bound to Search and Media Discovery so they stay in sync when the view mode changes.
    @Published var viewMode: SearchResultsViewMode
    @Published var showMediaDiscovery: Bool = false
    
    init(
        dependency: Dependency
    ) {
        viewMode = dependency.viewModeUseCase.viewModeForOpeningFolder(dependency.handle)
        
        $viewMode
            .map { $0 == .mediaDiscovery }
            .assign(to: &$showMediaDiscovery)
    }
}
