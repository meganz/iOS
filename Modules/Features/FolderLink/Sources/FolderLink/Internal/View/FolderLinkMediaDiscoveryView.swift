import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import Search
import SwiftUI

/// A view that displays a folder link in Media Discovery mode.
/// It shows all media nodes (images and videos) in the currently opened folder, and also in subfolders
/// if the `Gallery view in subfolders` setting is enabled.
struct FolderLinkMediaDiscoveryView<Content, DismissButton>: View where Content: View, DismissButton: View {
    struct Dependency {
        let handle: HandleEntity
        let link: String
        let nodeActionHandler: any FolderLinkNodeActionHandlerProtocol
        let content: (FolderLinkMediaDiscoveryViewModel) -> Content
        let dismissContent: () -> DismissButton
    }
    
    @StateObject private var viewModel: FolderLinkMediaDiscoveryViewModel
    private let dependency: Dependency
    
    init(
        dependency: Dependency,
        viewMode: Binding<SearchResultsViewMode>
    ) {
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: FolderLinkMediaDiscoveryViewModel(
                dependency: FolderLinkMediaDiscoveryViewModel.Dependency(handle: dependency.handle),
                viewMode: viewMode
            )
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            dependency.content(viewModel)
        }
        .navigationBarBackButtonHidden(true)
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
            
            if viewModel.shouldShowBottomBar {
                ToolbarItemGroup(placement: .bottomBar) {
                    bottomBar
                        .disabled(viewModel.bottomBarDisabled)
                }
            }
        }
        .onReceive(viewModel.$nodesAction.compactMap { $0 }) { action in
            dependency.nodeActionHandler.handle(action: action)
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
                // IOS-11083
            },
            rightView: {
                SearchResultsHeaderViewModeView(
                    viewModel: viewModel.viewModelViewModel,
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
        
        Spacer()
        FolderLinkBottomBarActionButton(action: .saveToPhotos, selection: $viewModel.bottomBarAction)
        
        Spacer()
        ShareLinkButton(link: dependency.link)
    }
}
