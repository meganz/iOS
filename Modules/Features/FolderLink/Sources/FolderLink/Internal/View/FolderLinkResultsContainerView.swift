import Combine
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import Search
import SwiftUI

/// A view that displays folder link nodes and conditionally switches between list/grid and Media Discovery modes.
/// It Holds the source of truth for the view mode
/// which is bound to Search and Media Discovery so they stay in sync when the view mode changes.
struct FolderLinkResultsContainerView<MediaDiscovery, DismissButton>: View where MediaDiscovery: FolderLinkMediaDiscoveryContent, DismissButton: View {
    struct Dependency {
        let handle: HandleEntity
        let link: String
        let searchResultMapper: any FolderLinkSearchResultMapperProtocol
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let nodeActionHandler: any FolderLinkNodeActionHandlerProtocol
        let selectionHandler: @MainActor (SearchResultSelection) -> Void
        let mediaDiscoveryContent: (FolderLinkMediaDiscoveryViewModel) -> MediaDiscovery
        let dismissContent: () -> DismissButton
        
        var searchResultsDependency: FolderLinkResultsView<DismissButton>.Dependency {
            FolderLinkResultsView.Dependency(
                handle: handle,
                link: link,
                searchResultMapper: searchResultMapper,
                sortOrderPreferenceUseCase: sortOrderPreferenceUseCase,
                nodeActionHandler: nodeActionHandler,
                selectionHandler: selectionHandler,
                dismissContent: dismissContent
            )
        }
        
        var mediaDiscoveryDependency: FolderLinkMediaDiscoveryView<MediaDiscovery, DismissButton>.Dependency {
            FolderLinkMediaDiscoveryView.Dependency(
                handle: handle,
                link: link,
                nodeActionHandler: nodeActionHandler,
                content: mediaDiscoveryContent,
                dismissContent: dismissContent
            )
        }
    }
    
    @StateObject private var viewModel: FolderLinkResultsContainerViewModel
    private let dependency: Dependency
    
    init(dependency: Dependency) {
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: FolderLinkResultsContainerViewModel(
                dependency: FolderLinkResultsContainerViewModel.Dependency(handle: dependency.handle)
            )
        )
    }
    
    var body: some View {
        if viewModel.showMediaDiscovery {
            FolderLinkMediaDiscoveryView(dependency: dependency.mediaDiscoveryDependency, viewMode: $viewModel.viewMode)
        } else {
            FolderLinkResultsView(dependency: dependency.searchResultsDependency, viewMode: $viewModel.viewMode)
        }
    }
}
