import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI
import Transfer

public struct FolderLinkView<LinkUnavailable, MediaDiscovery, MiniPlayer>: View where LinkUnavailable: View, MediaDiscovery: FolderLinkMediaDiscoveryContent, MiniPlayer: View {
    public struct Dependency {
        let link: String
        let folderLinkBuilder: any FolderLinkBuilderProtocol
        let folderLinkLogoutPolicy: any FolderLinkLogoutPolicyProtocol
        let searchResultsProvidingBuilder: any FolderLinkSearchResultsProvidingBuilderProtocol
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let fileNodeOpener: any FolderLinkFileNodeOpenerProtocol
        let nodeActionHandler: any FolderLinkNodeActionHandlerProtocol
        let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
        let mediaDiscoveryContent: (FolderLinkMediaDiscoveryViewModel) -> MediaDiscovery
        let onClose: @MainActor () -> Void
        let isLinkRevampEnabled: Bool

        public init(
            link: String,
            folderLinkBuilder: some FolderLinkBuilderProtocol,
            folderLinkLogoutPolicy: some FolderLinkLogoutPolicyProtocol,
            searchResultsProvidingBuilder: some FolderLinkSearchResultsProvidingBuilderProtocol,
            sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
            fileNodeOpener: some FolderLinkFileNodeOpenerProtocol,
            nodeActionHandler: some FolderLinkNodeActionHandlerProtocol,
            transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory,
            isLinkRevampEnabled: Bool,
            @ViewBuilder mediaDiscoveryContent: @escaping (FolderLinkMediaDiscoveryViewModel) -> MediaDiscovery,
            onClose: @escaping @MainActor () -> Void
        ) {
            self.link = link
            self.folderLinkBuilder = folderLinkBuilder
            self.folderLinkLogoutPolicy = folderLinkLogoutPolicy
            self.searchResultsProvidingBuilder = searchResultsProvidingBuilder
            self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
            self.fileNodeOpener = fileNodeOpener
            self.nodeActionHandler = nodeActionHandler
            self.transferIndicatorToolbarFactory = transferIndicatorToolbarFactory
            self.isLinkRevampEnabled = isLinkRevampEnabled
            self.mediaDiscoveryContent = mediaDiscoveryContent
            self.onClose = onClose
        }
    }
    
    enum NavigationRoute: Hashable {
        case folder(HandleEntity)
    }
    
    @StateObject private var viewModel: FolderLinkViewModel
    @State private var navigationPath = NavigationPath()
    @StateObject private var miniPlayerViewModel = FolderLinkMiniPlayerViewModel()

    /// Read here rather than where it is used because this is the last place that still sees it — see
    /// `EnvironmentValues.folderLinkBottomSafeAreaInset`.
    @State private var bottomSafeAreaInset: CGFloat = 0

    /// How tall the docked mini player is right now
    @State private var miniPlayerHeight: CGFloat = 0
    
    private let dependency: Dependency
    @ViewBuilder let linkUnavailableContent: (LinkUnavailableReason) -> LinkUnavailable
    @ViewBuilder let miniPlayerContent: (FolderLinkMiniPlayerViewModel) -> MiniPlayer
    
    public init(
        dependency: Dependency,
        @ViewBuilder linkUnavailableContent: @escaping (LinkUnavailableReason) -> LinkUnavailable,
        miniPlayerContent: @escaping (FolderLinkMiniPlayerViewModel) -> MiniPlayer
    ) {
        self.dependency = dependency
        self.linkUnavailableContent = linkUnavailableContent
        self.miniPlayerContent = miniPlayerContent
        _viewModel = StateObject(
            wrappedValue: FolderLinkViewModel(
                dependency: FolderLinkViewModel.Dependency(
                    link: dependency.link,
                    folderLinkBuilder: dependency.folderLinkBuilder,
                    folderLinkLogoutPolicy: dependency.folderLinkLogoutPolicy,
                    isLinkRevampEnabled: dependency.isLinkRevampEnabled
                )
            )
        )
    }
    
    public var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .navigationDestination(for: NavigationRoute.self) { route in
                    navigationDestinationBuilder(with: route)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    miniPlayerView
                }
        }
        .tint(TokenColors.Icon.primary.swiftUI)
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear { bottomSafeAreaInset = proxy.safeAreaInsets.bottom }
                    .onChange(of: proxy.safeAreaInsets.bottom) { _, inset in
                        bottomSafeAreaInset = inset
                    }
            }
        }
        .environment(\.folderLinkBottomSafeAreaInset, bottomSafeAreaInset)
        .environment(\.folderLinkMiniPlayerDocked, miniPlayerHeight > 0)
        .environment(\.networkConnected, viewModel.isNetworkConnected)
        .onAppear {
            viewModel.trackScreenView()
        }
        .task {
            await viewModel.onAppear()
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        if dependency.isLinkRevampEnabled {
            FolderLinkLoadingView()
        } else {
            ProgressView()
                .opacity(viewModel.askingForDecryptionKey || viewModel.notifyInvalidDecryptionKey ? 0 : 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            loadingIndicator
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(TokenColors.Background.page.swiftUI)
                .onFirstLoad {
                    await viewModel.startLoadingFolderLink()
                    // When first open folder link, calling retryPendingConnections after login to folder link
                    viewModel.retryPendingConnections()
                }
                .alert(
                    isPresented: $viewModel.askingForDecryptionKey,
                    .decryptionKey(
                        message: dependency.isLinkRevampEnabled
                            ? Strings.Localizable.Link.DecryptionKey.Alert.message
                            : Strings.Localizable.decryptionKeyAlertMessage,
                        placeholder: Strings.Localizable.decryptionKey,
                        confirm: { text in
                            Task {
                                await viewModel.confirmDecryptionKey(text)
                            }
                        }, cancel: {
                            viewModel.cancelConfirmingDecryptionKey()
                            dependency.onClose()
                        }
                    )
                )
                .invalidDecryptionKeyAlert(isPresented: $viewModel.notifyInvalidDecryptionKey) {
                    viewModel.acknowledgeInvalidDecryptionKey()
                }
                .noNetworkConnection()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        closeButton
                    }
                    
                    ToolbarItem(placement: .principal) {
                        loadingNavigationTitle
                    }
                }
        case let .error(reason):
            fullScreenLinkUnavailableContent(reason)
                .noNetworkConnection()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        closeButton
                    }
                    
                    ToolbarItem(placement: .principal) {
                        unavailableNavigationTitle
                    }
                }
        case let .results(nodeHandle):
            FolderLinkResultsContainerView(
                dependency: folderLinkResultsDependency(
                    handle: nodeHandle,
                    dismissContent: { closeButton }
                )
            )
        }
    }
    
    private func fullScreenLinkUnavailableContent(_ reason: LinkUnavailableReason) -> some View {
        GeometryReader { proxy in
            let topOffset = proxy.frame(in: .global).minY

            linkUnavailableContent(reason)
                .frame(width: proxy.size.width, height: proxy.size.height + topOffset)
                .offset(y: -topOffset)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func navigationDestinationBuilder(with route: NavigationRoute) -> some View {
        switch route {
        case let .folder(nodeHandle):
            FolderLinkResultsContainerView(
                dependency: folderLinkResultsDependency(
                    handle: nodeHandle,
                    dismissContent: { backButton }
                )
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                miniPlayerView
            }
            .task {
                // Calling retryPendingConnections whenever opening a folder
                viewModel.retryPendingConnections()
            }
        }
    }
    
    private var brandNavigationTitle: some View {
        FolderLinkNavigationTitleView(title: "MEGA", subtitle: Strings.Localizable.folderLink)
    }

    @ViewBuilder
    private var loadingNavigationTitle: some View {
        if dependency.isLinkRevampEnabled {
            brandNavigationTitle
        } else {
            FolderLinkNavigationTitleView(title: Strings.Localizable.folderLink, subtitle: nil)
        }
    }

    @ViewBuilder
    private var unavailableNavigationTitle: some View {
        if dependency.isLinkRevampEnabled {
            brandNavigationTitle
        } else {
            FolderLinkNavigationTitleView(
                title: Strings.Localizable.folderLink,
                subtitle: Strings.Localizable.unavailable
            )
        }
    }

    private var closeButton: some View {
        Button {
            viewModel.stopLoadingFolderLink()
            dependency.onClose()
        } label: {
            closeButtonLabel
        }
        .accessibilityLabel(Strings.Localizable.close)
    }

    @ViewBuilder
    private var closeButtonLabel: some View {
        if dependency.isLinkRevampEnabled {
            closeIcon
        } else {
            Text(Strings.Localizable.close)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
    }

    @ViewBuilder
    private var closeIcon: some View {
        let icon = MEGAAssets.Image.x
            .frame(width: TokenSpacing._7, height: TokenSpacing._7)
            .foregroundStyle(TokenColors.Icon.primary.swiftUI)

        if #available(iOS 26.0, *) {
            icon
        } else {
            icon.padding(10)
        }
    }
    
    private var backButton: some View {
        Button {
            guard !navigationPath.isEmpty else { return }
            navigationPath.removeLast()
        } label: {
            Image(uiImage: MEGAAssets.UIImage.backArrow)
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                .padding(10)
        }
    }
    
    /// Sized by the content itself — a mini player that is not showing collapses
    /// to nothing, so the inset costs nothing when no audio is playing.
    private var miniPlayerView: some View {
        miniPlayerContent(miniPlayerViewModel)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { miniPlayerHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { _, height in
                            miniPlayerHeight = height
                        }
                }
            }
    }
    
    private func folderLinkResultsDependency<DismissButton>(
        handle: HandleEntity,
        dismissContent: @escaping () -> DismissButton
    ) -> FolderLinkResultsContainerView<MediaDiscovery, DismissButton>.Dependency {
        FolderLinkResultsContainerView.Dependency(
            handle: handle,
            link: dependency.link,
            searchResultsProvidingBuilder: dependency.searchResultsProvidingBuilder,
            sortOrderPreferenceUseCase: dependency.sortOrderPreferenceUseCase,
            nodeActionHandler: dependency.nodeActionHandler,
            transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory,
            isLinkRevampEnabled: dependency.isLinkRevampEnabled,
            selectionHandler: { selection in
                if selection.result.isFolder {
                    navigationPath.append(NavigationRoute.folder(selection.result.id))
                } else {
                    dependency.fileNodeOpener.openNode(handle: selection.result.id, siblings: selection.siblings())
                }
            },
            mediaDiscoveryContent: dependency.mediaDiscoveryContent,
            dismissContent: dismissContent
        )
    }
}
