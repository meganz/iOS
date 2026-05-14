import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI
import Transfer

struct RecentActionBucketMediaView: View {
    struct Dependency {
        let router: any PhotoLibraryContentViewRouting
        let nodeActionHandler: any NodesActionHandling
        let moreActionsPresenter: any MoreNodeActionsPresenting
        let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
    }

    @StateObject private var viewModel: RecentActionBucketMediaViewModel
    private let dependency: Dependency
    private let bucket: RecentActionBucketEntity
    private let headerTitle: String
    @EnvironmentObject var navigator: HomeNavigation
    @EnvironmentObject var miniPlayerVisibility: MiniPlayerVisibility
    
    init(
        headerTitle: String,
        bucket: RecentActionBucketEntity,
        dependency: Dependency
    ) {
        self.dependency = dependency
        self.bucket = bucket
        self.headerTitle = headerTitle
        _viewModel = StateObject(
            wrappedValue: RecentActionBucketMediaViewModel(bucket: bucket)
        )
    }

    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    leadingBarButton
                }

                ToolbarItem(placement: .principal) {
                    titleView
                }

                dependency.transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: 1)

                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    trailingBarButton
                }

                if viewModel.editMode.isEditing {
                    ToolbarItemGroup(placement: .bottomBar) {
                        bottomBar
                    }
                }
            }
            .miniPlayerAware()
            .task {
                await viewModel.loadBucketItems()
                await viewModel.monitorBucketUpdates()
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
            .onDisappear {
                if let snackBar = viewModel.fileNoLongerAvailableSnackBar {
                    navigator.showSnackBar(snackBar)
                }
            }
    }

    private var content: some View {
        VStack(spacing: 0) {
            header
            mediaContent
        }
    }
    
    private var header: some View {
        Text(headerTitle)
            .font(.footnote)
            .fontWeight(.regular)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .padding(.horizontal, TokenSpacing._5)
            .padding(.vertical, TokenSpacing._2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TokenColors.Background.page.swiftUI)
    }
    
    private var mediaContent: some View {
        PhotoLibraryContentView(
            viewModel: viewModel.photoLibraryContentViewModel,
            router: dependency.router,
            onFilterUpdate: nil
        )
    }
    
    private var titleView: some View {
        RecentActionBucketNavigationTitleView(
            title: viewModel.navigationTitle.displayableTitle,
            subtitle: viewModel.navigationTitle.displayableSubtitle
        )
    }
    
    @ViewBuilder
    private var trailingBarButton: some View {
        if viewModel.editMode.isEditing {
            Button(Strings.Localizable.cancel) {
                viewModel.exitEditMode()
            }
        } else {
            Button {
                viewModel.enterEditMode()
            } label: {
                Label {
                    Text(Strings.Localizable.select)
                } icon: {
                    MEGAAssets.Image.checkCircle
                        .renderingMode(.template)
                        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                }
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
                        .padding(TokenSpacing._3)
                }
                .labelStyle(.iconOnly)
            }
        } else {
            BackButton()
        }
    }
    
    private var bottomBar: some View {
        RecentActionBucketItemsBottomBarView(
            bucket: bucket,
            bottomBarAction: $viewModel.bottomBarAction
        ) {
            dependency.moreActionsPresenter.presentActions(for: Set(viewModel.selectedPhotos.keys)) {
                viewModel.exitEditMode()
            }
        }
        .disabled(viewModel.bottomBarDisabled)
    }
}
