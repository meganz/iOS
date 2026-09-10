import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import Search
import SwiftUI
import Transfer

/// A view that displays a folder link in Media Discovery mode.
/// It shows all media nodes (images and videos) in the currently opened folder, and also in subfolders
/// if the `Gallery view in subfolders` setting is enabled.
struct FolderLinkMediaDiscoveryView<Content, DismissButton>: View where Content: View, DismissButton: View {
    struct Dependency {
        let handle: HandleEntity
        let link: String
        let nodeActionHandler: any FolderLinkNodeActionHandlerProtocol
        let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
        let isLinkRevampEnabled: Bool
        let content: (FolderLinkMediaDiscoveryViewModel) -> Content
        let dismissContent: () -> DismissButton
    }
    
    @StateObject private var viewModel: FolderLinkMediaDiscoveryViewModel
    @Environment(\.networkConnected) var networkConnected

    /// Held as `@State` rather than in the view model because it is flipped by a navigation bar button,
    /// whose action runs outside a SwiftUI transaction: a `@Published` write from there invalidates the
    /// view before it stores the new value, so the view re-reads the old one and is never invalidated
    /// again. `@State` stores first, then invalidates.
    @State private var isMoreOptionsSheetPresented = false

    private let dependency: Dependency
    
    init(
        dependency: Dependency,
        viewMode: Binding<SearchResultsViewMode>
    ) {
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: FolderLinkMediaDiscoveryViewModel(
                dependency: FolderLinkMediaDiscoveryViewModel.Dependency(
                    handle: dependency.handle,
                    link: dependency.link,
                    isLinkRevampEnabled: dependency.isLinkRevampEnabled
                ),
                viewMode: viewMode
            )
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            dependency.content(viewModel)
        }
        .noNetworkConnection()
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            anchoredButtons
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                topBarLeadingItem
            }
            
            ToolbarItem(placement: .principal) {
                FolderLinkNavigationTitleView(
                    title: viewModel.title,
                    subtitle: viewModel.subtitle)
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                moreOptionsButton
            }
            
            dependency.transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: 1)

            if viewModel.shouldShowBottomBar {
                ToolbarItemGroup(placement: .bottomBar) {
                    bottomBar
                        .disabled(viewModel.bottomBarDisabled || !networkConnected)
                }
            }
        }
        .onReceive(viewModel.$nodesAction.compactMap { $0 }) { action in
            dependency.nodeActionHandler.handle(action: action)
        }
        .folderLinkMoreOptionsSheet(
            isPresented: $isMoreOptionsSheetPresented,
            title: viewModel.title,
            subtitle: viewModel.subtitle,
            link: dependency.link,
            config: moreOptionsConfig,
            selectionHandler: viewModel.handle(moreOption:)
        )
    }
    
    /// Selection mode keeps the pre-revamp chrome — its redesign belongs to a separate ticket. Unlike the
    /// list/grid screen, gallery mode has no search button: its content is already the whole media set.
    private var showsRevampedChrome: Bool {
        dependency.isLinkRevampEnabled && !viewModel.editMode.isEditing
    }

    @ViewBuilder
    private var anchoredButtons: some View {
        if showsRevampedChrome {
            FolderLinkAnchoredButtons(
                selection: $viewModel.bottomBarAction,
                isDisabled: viewModel.bottomBarDisabled || !networkConnected
            )
        }
    }

    private var headerView: some View {
        ResultsHeaderView(
            height: 44,
            leftView: {
                SortHeaderView(
                    config: SortHeaderConfig.folderLinkMediaDiscovery,
                    selection: $viewModel.sortOrder
                )
                .simultaneousGesture(TapGesture().onEnded { [viewModel] _ in
                    viewModel.sortHeaderPressed()
                })
            },
            rightView: {
                SearchResultsHeaderViewModeView(
                    viewModel: viewModel.viewModeViewModel,
                    horizontalPadding: TokenSpacing._7
                )
            }
        )
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
                    selectAllIcon
                        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                }
                .labelStyle(.iconOnly)
            }
            .disabled(!networkConnected)
        } else {
            dependency.dismissContent()
        }
    }
    
    /// The revamp swaps the stacked squares for the ticked circle the design shows.
    private var selectAllIcon: Image {
        dependency.isLinkRevampEnabled ? MEGAAssets.Image.checkCircle : MEGAAssets.Image.checkStack
    }
    
    @ViewBuilder
    private var moreOptionsButton: some View {
        if viewModel.editMode.isEditing {
            Button {
                viewModel.editMode = .inactive
            } label: {
                Text(Strings.Localizable.cancel)
            }
        } else if showsRevampedChrome {
            Button {
                isMoreOptionsSheetPresented = true
            } label: {
                FolderLinkMoreOptionsLabel()
            }
            .disabled(moreOptionsConfig.isMoreOptionsButtonDisabled)
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
                        ShareLinkButton(link: dependency.link)
                        FolderLinkQuickActionButton(action: .sendToChat, selection: $viewModel.quickAction)
                    }
                }
            } label: {
                FolderLinkMoreOptionsLabel()
            }
            // Kept identical to the list/grid screen's pre-revamp gating.
            .disabled(!viewModel.shouldEnableMoreOptionsMenu || !networkConnected)
        }
    }
    
    private var moreOptionsConfig: FolderLinkMoreOptionsConfig {
        FolderLinkMoreOptionsConfig(
            canSelect: viewModel.shouldEnableMoreOptionsMenu,
            showsQuickActions: viewModel.shouldShowQuickActionsMenu,
            savesToPhotos: viewModel.shouldIncludeSaveToPhotosBottomAction,
            isNetworkConnected: networkConnected
        )
    }

    @ViewBuilder
    private var bottomBar: some View {
        if dependency.isLinkRevampEnabled {
            selectionToolbar
        } else {
            legacyBottomBar
        }
    }
    
    @ViewBuilder
    private var selectionToolbar: some View {
        FolderLinkBottomBarActionButton(action: .makeAvailableOffline, selection: $viewModel.bottomBarAction)
        
        Spacer()
        FolderLinkBottomBarActionButton(action: .downloadToFiles, selection: $viewModel.bottomBarAction)
        
        Spacer()
        FolderLinkBottomBarActionButton(action: .addToCloudDrive, selection: $viewModel.bottomBarAction)
        
        Spacer()
        FolderLinkBottomBarActionButton(action: .saveToPhotos, selection: $viewModel.bottomBarAction)
    }
    
    @ViewBuilder
    private var legacyBottomBar: some View {
        FolderLinkBottomBarActionButton(action: .addToCloudDrive, selection: $viewModel.bottomBarAction)
        
        Spacer()
        FolderLinkBottomBarActionButton(action: .makeAvailableOffline, selection: $viewModel.bottomBarAction)
        
        Spacer()
        FolderLinkBottomBarActionButton(action: .saveToPhotos, selection: $viewModel.bottomBarAction)
        
        Spacer()
        ShareLinkButton(link: dependency.link)
    }
}
