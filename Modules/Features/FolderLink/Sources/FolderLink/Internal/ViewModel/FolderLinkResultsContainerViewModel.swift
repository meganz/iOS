import Combine
import MEGADomain
import Search

@MainActor
final class FolderLinkResultsContainerViewModel: ObservableObject {
    struct Dependency {
        let handle: HandleEntity
        let viewModeUseCase: any FolderLinkViewModeUseCaseProtocol
        let trackingUseCase: any FolderLinkTrackingUseCaseProtocol
        
        init(
            handle: HandleEntity,
            viewModeUseCase: some FolderLinkViewModeUseCaseProtocol,
            trackingUseCase: some FolderLinkTrackingUseCaseProtocol
        ) {
            self.handle = handle
            self.viewModeUseCase = viewModeUseCase
            self.trackingUseCase = trackingUseCase
        }
        
        init(handle: HandleEntity) {
            self.init(
                handle: handle,
                viewModeUseCase: FolderLinkViewModeUseCase(),
                trackingUseCase: FolderLinkTrackingUseCase()
            )
        }
    }
    
    /// Holds the source of truth for the view mode.
    /// It is bound to Search and Media Discovery so they stay in sync when the view mode changes.
    @Published var viewMode: SearchResultsViewMode
    @Published var showMediaDiscovery: Bool = false
    private var subscriptions: Set<AnyCancellable> = []
    
    init(
        dependency: Dependency
    ) {
        viewMode = dependency.viewModeUseCase.viewModeForOpeningFolder(dependency.handle)
        
        $viewMode
            .map { $0 == .mediaDiscovery }
            .assign(to: &$showMediaDiscovery)
        
        $viewMode
            .dropFirst()
            .sink { mode in
                dependency.trackingUseCase.trackViewModeChanged(mode)
            }
            .store(in: &subscriptions)
    }
}
