import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import Search
import SwiftUI

struct FolderLinkResultsView: View {
    struct Dependency {
        let handle: HandleEntity
        let searchResultMapper: any FolderLinkSearchResultMapperProtocol
        let selectionHandler: @MainActor (SearchResultSelection) -> Void
    }
    
    @StateObject private var viewModel: FolderLinkResultsViewModel
    
    let dependency: Dependency
    
    init(dependency: FolderLinkResultsView.Dependency) {
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: FolderLinkResultsViewModel(
                dependency: FolderLinkResultsViewModel.Dependency(
                    nodeHandle: dependency.handle,
                    searchResultMapper: dependency.searchResultMapper,
                    titleUseCase: FolderLinkTitleUseCase(),
                    viewModeUseCase: FolderLinkViewModeUseCase(),
                    isCloudDriveRevampEnabled: DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosCloudDriveRevamp)
                )
            )
        )
    }
    
    var body: some View {
        SearchResultsContainerView(viewModel: viewModel.searchResultsContainerViewModel)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbarRole(.editor)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(viewModel.title)
                            .font(.headline)
                            .foregroundStyle(TokenColors.Text.primary.swiftUI)
                            .lineLimit(1)
                        Text(viewModel.subtitle)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                            .lineLimit(1)
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    moreOptions
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    bottomToolbar
                }
            }
            .onReceive(viewModel.$selection.compactMap { $0 }) { selection in
                dependency.selectionHandler(selection)
            }
    }
    
    private var moreOptions: some View {
        Button {
            // todo moreOptions
        } label: {
            Image(uiImage: MEGAAssets.UIImage.moreNavigationBar)
        }
    }
    
    @ViewBuilder
    private var bottomToolbar: some View {
        Button {
            // todo import
        } label: {
            MEGAAssets.Image.import
        }
        
        Spacer()
        
        Button {
            // todo download
        } label: {
            MEGAAssets.Image.offline
        }
        
        Spacer()
        
        Button {
            // todo save to photos
        } label: {
            MEGAAssets.Image.saveToPhotos
        }
        
        Spacer()
        
        Button {
            // todo share link
        } label: {
            MEGAAssets.Image.link
        }
    }
}
