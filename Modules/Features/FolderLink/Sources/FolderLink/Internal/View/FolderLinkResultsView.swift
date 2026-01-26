import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPreference
import Search
import SwiftUI

/// A view that uses the Search module to render folder link nodes in either a list or grid layout.
struct FolderLinkResultsView<DismissButton>: View where DismissButton: View {
    struct Dependency {
        let handle: HandleEntity
        let link: String
        let searchResultMapper: any FolderLinkSearchResultMapperProtocol
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let nodeActionHandler: any FolderLinkNodeActionHandlerProtocol
        let selectionHandler: @MainActor (SearchResultSelection) -> Void
        let dismissContent: () -> DismissButton
    }
    
    @StateObject private var viewModel: FolderLinkResultsViewModel
    private let dependency: Dependency
    
    init(
        dependency: FolderLinkResultsView.Dependency,
        viewMode: Binding<SearchResultsViewMode>
    ) {
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: FolderLinkResultsViewModel(
                dependency: FolderLinkResultsViewModel.Dependency(
                    nodeHandle: dependency.handle,
                    link: dependency.link,
                    searchResultMapper: dependency.searchResultMapper,
                    titleUseCase: FolderLinkTitleUseCase(),
                    viewModeUseCase: FolderLinkViewModeUseCase(),
                    searchUseCase: FolderLinkSearchUseCase(),
                    editModeUseCase: FolderLinkEditModeUseCase(),
                    bottomBarUseCase: FolderLinkBottomBarUseCase(),
                    quickActionUseCase: FolderLinkQuickActionUseCase(),
                    sortOrderPreferenceUseCase: dependency.sortOrderPreferenceUseCase
                ),
                viewMode: viewMode
            )
        )
    }
    
    var body: some View {
        FolderLinkResultsSearchableView(viewModel: viewModel.searchResultsContainerViewModel, searchBecameActive: $viewModel.searchBecameActive)
            .background(TokenColors.Background.page.swiftUI)
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    topBarLeadingItem
                }
                
                ToolbarItem(placement: .principal) {
                    FolderLinkNavigationTitleView(title: viewModel.title, subtitle: viewModel.subtitle)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    moreOptionsButton
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    bottomBar
                        .disabled(viewModel.bottomBarDisabled)
                }
            }
            .onReceive(viewModel.$selection.compactMap { $0 }) { selection in
                dependency.selectionHandler(selection)
            }.onReceive(viewModel.$nodeAction.compactMap { $0 }) { action in
                dependency.nodeActionHandler.handle(action: action)
            }
            .onReceive(viewModel.$nodesAction.compactMap { $0 }) { action in
                dependency.nodeActionHandler.handle(action: action)
            }
            .environment(\.editMode, $viewModel.editMode)
    }
    
    @ViewBuilder
    private var topBarLeadingItem: some View {
        if viewModel.editMode.isEditing {
            Button {
                viewModel.toggleSelectAll()
            } label: {
                MEGAAssets.Image.checkStack
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            }
        } else {
            dependency.dismissContent()
        }
    }
    
    @ViewBuilder
    private var moreOptionsButton: some View {
        if viewModel.editMode.isEditing {
            Button {
                viewModel.editMode = .inactive
            } label: {
                Text(Strings.Localizable.cancel)
            }
        } else {
            Menu {
                Section {
                    Button {
                        viewModel.editMode = .active
                    } label: {
                        Label {
                            Text(Strings.Localizable.select)
                        } icon: {
                            Image(uiImage: MEGAAssets.UIImage.selectItem)
                        }
                    }
                }
                
                if viewModel.shouldShowQuickActionsMenu {
                    Section {
                        FolderLinkQuickActionButton(action: .addToCloudDrive, selection: $viewModel.quickAction)
                        FolderLinkQuickActionButton(action: .makeAvailableOffline, selection: $viewModel.quickAction)
                        ShareLinkButton(link: dependency.link)
                        FolderLinkQuickActionButton(action: .sendToChat, selection: $viewModel.quickAction)
                    }
                }
            } label: {
                Label {
                    Text(Strings.Localizable.more)
                } icon: {
                    Image(uiImage: MEGAAssets.UIImage.moreNavigationBar)
                }
            }
            .disabled(!viewModel.shouldEnableMoreOptionsMenu)
        }
    }
    
    @ViewBuilder
    private var bottomBar: some View {
        FolderLinkBottomBarActionButton(action: .addToCloudDrive, selection: $viewModel.bottomBarAction)
        
        Spacer()
        FolderLinkBottomBarActionButton(action: .makeAvailableOffline, selection: $viewModel.bottomBarAction)
        
        if viewModel.shouldIncludeSaveToPhotosBottomAction {
            Spacer()
            FolderLinkBottomBarActionButton(action: .saveToPhotos, selection: $viewModel.bottomBarAction)
        }
        
        Spacer()
        ShareLinkButton(link: dependency.link)
    }
}

/// This view is needed to access the `isSearching` environment value and bind it back to FolderLinkResultsViewModel's searchBecameActive
/// searchBecameActive is needed for Search to switch between Search chips and Sort & View mode header.
struct FolderLinkResultsSearchableView: View {
    @Environment(\.isSearching) private var isSearching
    let viewModel: SearchResultsContainerViewModel
    @Binding var searchBecameActive: Bool
    
    var body: some View {
        SearchResultsContainerView(viewModel: viewModel)
            .onChange(of: isSearching) { isSearching in
                searchBecameActive = isSearching
            }
    }
}
