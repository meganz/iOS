import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI

struct RecentActionBucketItemsView: View {
    struct Dependency {
        let bucket: RecentActionBucketEntity
        let resultMapper: any RecentActionBucketItemResultMapping
        let downloadedNodesListener: any DownloadedNodesListening
        let selectionHandler: any NodeSelectionHandling
        let nodeActionHandler: any NodesActionHandling
        let moreActionsPresenter: any MoreNodeActionsPresenting
    }

    @StateObject private var viewModel: RecentActionBucketItemsViewModel
    private let dependency: Dependency
    @EnvironmentObject var navigator: HomeNavigation
    @EnvironmentObject var miniPlayerVisibility: MiniPlayerVisibility
    
    init(dependency: Dependency) {
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: RecentActionBucketItemsViewModel(
                dependency: RecentActionBucketItemsViewModel.Dependency(
                    bucket: dependency.bucket,
                    resultMapper: dependency.resultMapper,
                    downloadedNodesListener: dependency.downloadedNodesListener
                )
            )
        )
    }
    
    var body: some View {
        SearchResultsContainerView(viewModel: viewModel.searchResultsContainerViewModel)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    RecentActionBucketNavigationTitleView(
                        title: viewModel.navigationTitle,
                        subtitle: viewModel.navigationSubtitle
                    )
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    leadingBarButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    trailingBarButton
                }
                
                if viewModel.editMode.isEditing {
                    ToolbarItemGroup(placement: .bottomBar) {
                        RecentActionBucketItemsBottomBarView(
                            bucket: dependency.bucket,
                            bottomBarAction: $viewModel.bottomBarAction
                        ) {
                            dependency.moreActionsPresenter.presentActions(for: viewModel.selectedNodes) {
                                viewModel.editMode = .inactive
                            }
                        }
                        .disabled(viewModel.selectedNodes.isEmpty)
                    }
                }
            }
            .miniPlayerAware()
            .environment(\.editMode, $viewModel.editMode)
            .onReceive(viewModel.$selection.compactMap { $0 }) { selection in
                dependency.selectionHandler.handle(selection: selection)
            }
            .onReceive(viewModel.$nodeAction.compactMap { $0 }) { action in
                dependency.nodeActionHandler.handle(action: action)
            }
            .onReceive(viewModel.$nodesAction.compactMap { $0 }) { action in
                dependency.nodeActionHandler.handle(action: action)
            }
            .onChange(of: viewModel.editMode) { mode in
                navigator.tabBarHidden = mode.isEditing
                miniPlayerVisibility.isHidden = mode.isEditing
            }
            .onChange(of: viewModel.isBucketEmpty) { isEmpty in
                guard isEmpty else { return }
                navigator.removeLast()
            }
            .task {
                await viewModel.observeEmptyItemsEvent()
            }
            .onDisappear {
                if let snackBar = viewModel.fileNoLongerAvailableSnackBar {
                    navigator.showSnackBar(snackBar)
                }
            }
    }

    @ViewBuilder
    private var leadingBarButton: some View {
        if viewModel.editMode.isEditing {
            Button {
                viewModel.toggleSelectAll()
            } label: {
                Label {
                    Text(Strings.Localizable.selectAll)
                } icon: {
                    MEGAAssets.Image.checkStack
                        .renderingMode(.template)
                        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        .padding(10)
                }
                .labelStyle(.iconOnly)
            }
        } else {
            BackButton()
        }
    }

    @ViewBuilder
    private var trailingBarButton: some View {
        if viewModel.editMode.isEditing {
            Button(Strings.Localizable.cancel) {
                viewModel.editMode = .inactive
            }
        }
    }
    
}
