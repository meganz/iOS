import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPreference
import Search
import SwiftUI

struct FolderLinkResultsView: View {
    struct Dependency {
        let handle: HandleEntity
        let searchResultMapper: any FolderLinkSearchResultMapperProtocol
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let nodeActionHandler: any FolderLinkNodeActionHandlerProtocol
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
                    searchUseCase: FolderLinkSearchUseCase(),
                    quickActionUseCase: FolderLinkQuickActionUseCase(),
                    sortOrderPreferenceUseCase: dependency.sortOrderPreferenceUseCase
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
                    if viewModel.editMode.isEditing {
                        Button {
                            viewModel.editMode = .inactive
                        } label: {
                            Text(Strings.Localizable.cancel)
                        }
                    } else {
                        moreOptions
                    }
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    bottomToolbar
                }
            }
            .onReceive(viewModel.$selection.compactMap { $0 }) { selection in
                dependency.selectionHandler(selection)
            }.onReceive(viewModel.$nodeAction.compactMap { $0 }) { action in
                dependency.nodeActionHandler.handle(action: action)
            }
            .environment(\.editMode, $viewModel.editMode)
    }
    
    @ViewBuilder
    private var moreOptions: some View {
        Menu {
            Section {
                EditModeMenu(editMode: $viewModel.editMode)
            }
            
            if !viewModel.quickActions.isEmpty {
                Section {
                    QuickActionMenu(
                        quickActions: viewModel.quickActions,
                        selection: $viewModel.quickAction
                    )
                }
            }
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
