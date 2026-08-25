import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI
import Transfer

/// Entry point of the file link screen. It owns the access flow only: the screen is on top before the
/// link is resolved, shows the skeleton while that happens, asks for a decryption key when the link
/// was shared without one, and shows the unavailable state when the link cannot be opened.
///
/// `adsContent` is the ad the caller wants shown to free accounts, which this module knows nothing
/// about: it only reserves the place the design gives it, below the file's details. Pass `EmptyView`
/// for a screen that shows no ads.
public struct FileLinkView<Ads, LinkUnavailable>: View where Ads: View, LinkUnavailable: View {
    public struct Dependency {
        let link: String
        /// Set when the link the user opened was an encrypted one, of which `link` is the decrypted form.
        /// It is the form the link was published in, so it is the one the Share link row hands on.
        let encryptedLink: String?
        let fileLinkBuilder: any FileLinkBuilderProtocol
        let fileNodeOpener: any FileLinkNodeOpenerProtocol
        let actionHandler: any FileLinkActionHandlerProtocol
        let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
        let onClose: @MainActor () -> Void
        /// Shared by the link resolution, which stores the node it resolved, and everything that needs
        /// that node afterwards: the preview loader in here, `fileNodeOpener` and `actionHandler` out
        /// there. See `FileLinkNodeProvider`.
        let nodeProvider: FileLinkNodeProvider

        /// `nodeProvider` has to be the very instance `fileNodeOpener` and `actionHandler` read from,
        /// which is why the caller owns it rather than this initialiser creating one.
        public init(
            link: String,
            encryptedLink: String?,
            fileLinkBuilder: some FileLinkBuilderProtocol,
            fileNodeOpener: some FileLinkNodeOpenerProtocol,
            actionHandler: some FileLinkActionHandlerProtocol,
            transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory,
            nodeProvider: FileLinkNodeProvider,
            onClose: @escaping @MainActor () -> Void
        ) {
            self.link = link
            self.encryptedLink = encryptedLink
            self.fileLinkBuilder = fileLinkBuilder
            self.fileNodeOpener = fileNodeOpener
            self.actionHandler = actionHandler
            self.transferIndicatorToolbarFactory = transferIndicatorToolbarFactory
            self.nodeProvider = nodeProvider
            self.onClose = onClose
        }
    }

    @StateObject private var viewModel: FileLinkViewModel

    /// Read here rather than where it is used because this is the last place that still sees it -- see
    /// `EnvironmentValues.fileLinkBottomSafeAreaInset`.
    @State private var bottomSafeAreaInset: CGFloat = 0

    private let dependency: Dependency
    /// Built once, next to the view model, so that resolving the body does not rebuild it.
    private let previewLoader: any ThumbnailLoaderProtocol
    @ViewBuilder let adsContent: () -> Ads
    @ViewBuilder let linkUnavailableContent: (LinkUnavailableReason) -> LinkUnavailable

    public init(
        dependency: Dependency,
        @ViewBuilder adsContent: @escaping () -> Ads,
        @ViewBuilder linkUnavailableContent: @escaping (LinkUnavailableReason) -> LinkUnavailable
    ) {
        self.dependency = dependency
        self.adsContent = adsContent
        self.linkUnavailableContent = linkUnavailableContent
        previewLoader = FileLinkPreviewLoaderFactory.makePreviewLoader(nodeProvider: dependency.nodeProvider)
        _viewModel = StateObject(
            wrappedValue: FileLinkViewModel(
                dependency: FileLinkViewModel.Dependency(
                    link: dependency.link,
                    encryptedLink: dependency.encryptedLink,
                    fileLinkBuilder: dependency.fileLinkBuilder,
                    nodeProvider: dependency.nodeProvider
                )
            )
        )
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
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
        .environment(\.fileLinkBottomSafeAreaInset, bottomSafeAreaInset)
        .environment(\.networkConnected, viewModel.isNetworkConnected)
        .task {
            await viewModel.monitorNetworkConnection()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            FileLinkLoadingView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(TokenColors.Background.page.swiftUI)
                .onFirstLoad {
                    await viewModel.startLoadingFileLink()
                }
                .alert(
                    isPresented: $viewModel.askingForDecryptionKey,
                    .decryptionKey(
                        message: Strings.Localizable.Link.DecryptionKey.Alert.message,
                        placeholder: Strings.Localizable.decryptionKey,
                        confirm: { text in
                            Task {
                                await viewModel.confirmDecryptionKey(text)
                            }
                        }, cancel: {
                            viewModel.stopLoadingFileLink()
                            dependency.onClose()
                        }
                    )
                )
                .alert(
                    Strings.Localizable.decryptionKeyNotValid,
                    isPresented: $viewModel.notifyInvalidDecryptionKey
                ) {
                    Button(Strings.Localizable.ok) {
                        viewModel.acknowledgeInvalidDecryptionKey()
                    }
                }
                .toolbar { toolbarContent }
        case let .loaded(node):
            FileLinkContentView(
                node: node,
                previewLoader: previewLoader,
                fileNodeOpener: dependency.fileNodeOpener,
                actionHandler: dependency.actionHandler,
                // Read from the view model rather than from the dependency: only it knows which link the
                // file resolved from, which is not the one the screen was opened with when the user had to
                // type the key in.
                shareLink: viewModel.shareLink,
                transferIndicatorToolbarFactory: dependency.transferIndicatorToolbarFactory,
                adsContent: adsContent
            )
            .toolbar { toolbarContent }
        case let .error(reason):
            fullScreenLinkUnavailableContent(reason)
                // The design draws the bar as transparent page background, with only the close
                // button carrying a glass capsule.
                .hideNavigationToolbarBackground()
                .toolbar { toolbarContent }
        }
    }

    /// Centres the unavailable state on the whole screen rather than on the area below the
    /// navigation bar, which is transparent here. Same treatment as the folder link.
    private func fullScreenLinkUnavailableContent(_ reason: LinkUnavailableReason) -> some View {
        GeometryReader { proxy in
            let topOffset = proxy.frame(in: .global).minY

            linkUnavailableContent(reason)
                .frame(width: proxy.size.width, height: proxy.size.height + topOffset)
                .offset(y: -topOffset)
        }
        .ignoresSafeArea()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            closeButton
        }

        ToolbarItem(placement: .principal) {
            titleView
        }
    }

    private var titleView: some View {
        VStack {
            Text(viewModel.navigationTitle)
                .font(.headline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .lineLimit(1)

            Text(viewModel.navigationSubtitle)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .lineLimit(1)
        }
    }

    private var closeButton: some View {
        Button {
            viewModel.stopLoadingFileLink()
            dependency.onClose()
        } label: {
            closeIcon
        }
        .accessibilityLabel(Strings.Localizable.close)
    }

    /// From iOS 26 the toolbar puts the icon in a glass capsule of its own, so the padding that
    /// gives it a tappable area on earlier versions would double up.
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
}
