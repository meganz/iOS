import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGASwiftUI
import Search
import SwiftUI

/// A view that uses the Search module to render folder link nodes in either a list or grid layout.
struct FolderLinkResultsView<DismissButton>: View where DismissButton: View {
    struct Dependency {
        let handle: HandleEntity
        let link: String
        let searchResultsProvidingBuilder: any FolderLinkSearchResultsProvidingBuilderProtocol
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let nodeActionHandler: any FolderLinkNodeActionHandlerProtocol
        let isLinkRevampEnabled: Bool
        let selectionHandler: @MainActor (SearchResultSelection) -> Void
        let dismissContent: () -> DismissButton
    }
    
    @StateObject private var viewModel: FolderLinkResultsViewModel
    @Environment(\.networkConnected) var networkConnected
    
    /// Whether the collapsed search bar of the revamp is up. It is held here rather than in the view model
    /// because the search button lives in the toolbar, whose actions run outside a SwiftUI transaction: a
    /// `@Published` write from there invalidates the view before it stores the new value, so the view
    /// re-reads the old one and is never invalidated again. `@State` stores first, then invalidates.
    @State private var isSearchActive = false
    
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
                    searchResultsProvidingBuilder: dependency.searchResultsProvidingBuilder,
                    sortOrderPreferenceUseCase: dependency.sortOrderPreferenceUseCase
                ),
                viewMode: viewMode
            )
        )
    }
    
    var body: some View {
        FolderLinkResultsSearchableView(viewModel: viewModel.searchResultsContainerViewModel, searchBecameActive: $viewModel.searchBecameActive)
            .background(TokenColors.Background.page.swiftUI)
            .folderLinkSearchable(
                text: $viewModel.searchText,
                isActive: $isSearchActive,
                collapsedIntoNavigationBar: dependency.isLinkRevampEnabled
            )
            .noNetworkConnection()
            .navigationBarBackButtonHidden(true)
            .safeAreaInset(edge: .bottom) {
                anchoredButtons
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    topBarLeadingItem
                }
                
                ToolbarItem(placement: .principal) {
                    FolderLinkNavigationTitleView(title: viewModel.title, subtitle: viewModel.subtitle)
                }
                
                // Trailing items lay out in the order they are declared, so search sits left of the menu.
                if showsRevampedChrome {
                    ToolbarItem(placement: .topBarTrailing) {
                        searchButton
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    moreOptionsButton
                }

                if !showsRevampedChrome {
                    ToolbarItemGroup(placement: .bottomBar) {
                        bottomBar
                            .disabled(viewModel.bottomBarDisabled || !networkConnected)
                    }
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
            // The pre-revamp search field reports through the isSearching environment value, the collapsed
            // one through this. Either way the view model hears about it the same way.
            .onChange(of: isSearchActive) { _, isActive in
                viewModel.searchBecameActive = isActive
            }
    }
    
    /// Selection mode keeps the pre-revamp chrome — its redesign belongs to a separate ticket.
    private var showsRevampedChrome: Bool {
        dependency.isLinkRevampEnabled && !viewModel.editMode.isEditing
    }

    private var isSearchExpanded: Bool {
        dependency.isLinkRevampEnabled && isSearchActive
    }

    private var searchButton: some View {
        Button {
            isSearchActive = true
        } label: {
            Label {
                Text(Strings.Localizable.search)
            } icon: {
                Image(uiImage: MEGAAssets.UIImage.search)
            }
            .labelStyle(.iconOnly)
        }
    }

    @ViewBuilder
    private var anchoredButtons: some View {
        if showsRevampedChrome, !isSearchExpanded {
            FolderLinkAnchoredButtons(
                selection: $viewModel.bottomBarAction,
                isDisabled: viewModel.bottomBarDisabled || !networkConnected
            )
        }
    }

    @ViewBuilder
    private var topBarLeadingItem: some View {
        if viewModel.editMode.isEditing {
            Button {
                viewModel.toggleSelectAll()
            } label: {
                Label {
                    Text(Strings.Localizable.selectAll)
                } icon: {
                    MEGAAssets.Image.checkStack
                        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                }
                .labelStyle(.iconOnly)
            }
            .disabled(!networkConnected)
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
                            Image(uiImage: MEGAAssets.UIImage.checkCircle)
                        }
                    }
                    // Selecting needs something to select; the other actions in this menu do not.
                    .disabled(!viewModel.shouldEnableMoreOptionsMenu)
                }
                
                if viewModel.shouldShowQuickActionsMenu {
                    Section {
                        FolderLinkQuickActionButton(action: .addToCloudDrive, selection: $viewModel.quickAction)
                        FolderLinkQuickActionButton(action: .makeAvailableOffline, selection: $viewModel.quickAction)
                        // Save to Photos lost its bottom bar slot to the two anchored buttons.
                        if showsRevampedChrome, viewModel.shouldIncludeSaveToPhotosBottomAction {
                            FolderLinkBottomBarActionMenuButton(action: .saveToPhotos, selection: $viewModel.bottomBarAction)
                        }
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
            .disabled(moreOptionsMenuDisabled)
        }
    }

    /// The revamped menu took over Share link from the bottom bar, where it stayed enabled for a folder
    /// with no children, so it cannot be gated on Select alone any more — it is disabled only once every
    /// row it holds is. The pre-revamp menu holds no such action, so it keeps its original gating.
    private var moreOptionsMenuDisabled: Bool {
        guard showsRevampedChrome else {
            return !viewModel.shouldEnableMoreOptionsMenu || !networkConnected
        }
        return !networkConnected || (!viewModel.shouldEnableMoreOptionsMenu && !viewModel.shouldShowQuickActionsMenu)
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

private extension View {
    /// Installs the folder link search field, either as the permanently visible drawer of the
    /// pre-revamp design or collapsed behind the navigation bar search button of the revamp.
    ///
    /// The revamp cannot use `searchable` for this: collapsing it means attaching it only while search is
    /// active, and detaching it on cancel resets the results list's scroll position and dismisses the
    /// modally presented folder link along with the search bar.
    @ViewBuilder
    func folderLinkSearchable(
        text: Binding<String>,
        isActive: Binding<Bool>,
        collapsedIntoNavigationBar: Bool
    ) -> some View {
        if collapsedIntoNavigationBar {
            navigationBarSearchController(text: text, isActive: isActive)
                // Without this the search bar is absorbed into the bottom toolbar, which is where
                // iOS 26 puts it on iPhone by default.
                .disableSearchBarToolbarIntegration()
                .searchableTransitionWorkaround()
        } else {
            searchable(text: text, placement: .navigationBarDrawer(displayMode: .always))
        }
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
            .onChange(of: isSearching) { _, isSearching in
                searchBecameActive = isSearching
            }
    }
}
