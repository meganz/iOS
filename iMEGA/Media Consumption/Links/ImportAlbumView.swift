import ContentLibraries
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI
import Transfer

struct ImportAlbumView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject var viewModel: ImportAlbumViewModel
    
    let transferIndicatorToolbarFactory: TransferIndicatorToolbarFactory
    let invokeDismiss: () -> Void
    
    @State private var publicAlbumLoadingTask: Task<Void, Never>?
    
    /// Read here rather than where it is used because this is the last place that still sees it -- see
    /// `AlbumLinkAnchoredButtons.bottomSafeAreaInset`.
    @State private var bottomSafeAreaInset: CGFloat = 0
    
    var body: some View {
        
        Group {
            if viewModel.shouldShowLinkUnavailable {
                // Closing from here dismisses without resetting the link status: resetting it would
                // put the album content back on screen, and with it the request that failed.
                AlbumLinkUnavailableView(onClose: invokeDismiss)
            } else {
                albumContent
            }
        }
        .onAppear {
            viewModel.onViewAppear()
        }
        .onReceive(viewModel.$showLoading.dropFirst()) {
            $0 ? SVProgressHUD.show() : SVProgressHUD.dismiss()
        }
        .onReceive(viewModel.$showNoInternetConnection.dropFirst()) {
            guard $0 else { return }
            SVProgressHUD.dismiss()
            SVProgressHUD.show(MEGAAssets.UIImage.hudForbidden,
                               status: Strings.Localizable.noInternetConnection)
        }
    }
    
    private var albumContent: some View {
        NavigationStack {
            albumBody
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    anchoredButtons
                }
                .toolbar { toolbarContent }
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
    }

    @ViewBuilder
    private var anchoredButtons: some View {
        if viewModel.showsAnchoredButtons {
            AlbumLinkAnchoredButtons(
                isDisabled: viewModel.isToolbarButtonsDisabled,
                bottomSafeAreaInset: bottomSafeAreaInset
            ) {
                Task { await viewModel.importAlbum() }
            }
        }
    }
    
    private var albumBody: some View {
        albumBodyModals
            .task {
                viewModel.monitorNetworkConnection()
            }
            .alert(
                isPresented: $viewModel.showingDecryptionKeyAlert,
                .decryptionKey(
                    message: viewModel.decryptionKeyAlertMessage,
                    placeholder: viewModel.decryptionKeyAlertPlaceholder,
                    confirm: { decryptionKey in
                        viewModel.publicLinkDecryptionKey = decryptionKey
                        publicAlbumLoadingTask = Task {
                            await viewModel.loadWithNewDecryptionKey()
                        }
                    },
                    cancel: dismissImportAlbumScreen
                )
            )
            .alert(
                Strings.Localizable.decryptionKeyNotValid,
                isPresented: $viewModel.showInvalidDecryptionKeyAlert
            ) {
                Button(Strings.Localizable.ok) {
                    viewModel.acknowledgeInvalidDecryptionKey()
                }
            }
    }
    
    /// The modals the bottom bar buttons drive are attached here, not to the buttons themselves:
    /// toolbar items live outside the regular view hierarchy, so what hangs off them can be dropped
    /// the same way it was for the decryption key alert.
    private var albumBodyModals: some View {
        networkAwareContent
            .fullScreenCover(isPresented: $viewModel.showStorageQuotaWillExceed) {
                CustomModalAlertView(mode: .storageQuotaWillExceed(displayMode: .albumLink))
            }
            .alert(isPresented: $viewModel.showRenameAlbumAlert,
                   viewModel.renameAlbumAlertViewModel())
            .sheet(isPresented: $viewModel.showImportAlbumLocation) {
                BrowserView(browserAction: .saveToCloudDrive,
                            isChildBrowser: true,
                            parentNode: MEGASdk.shared.rootNode,
                            selectedNode: $viewModel.importFolderLocation)
                .ignoresSafeArea(edges: .bottom)
            }
            .alertPhotosPermission(isPresented: $viewModel.showPhotoPermissionAlert)
            .share(isPresented: $viewModel.showShareLink, activityItems: [viewModel.shareableLink])
            .albumLinkMoreOptionsSheet(
                isPresented: $viewModel.showMoreOptions,
                title: viewModel.publicAlbumName ?? Strings.Localizable.albumLink,
                subtitle: Strings.Localizable.albumLink,
                cover: viewModel.albumCover,
                link: viewModel.shareableLink.absoluteString,
                options: viewModel.moreOptions,
                disabledOptions: viewModel.disabledMoreOptions,
                selectionHandler: { viewModel.handle(moreOption: $0) }
            )
    }
    
    @ViewBuilder
    private var networkAwareContent: some View {
        if viewModel.isConnectedToNetworkUntilContentLoaded {
            content()
                .snackBar($viewModel.snackBar)
        } else {
            ContentUnavailableView {
                MEGAAssets.Image.noInternetEmptyState
            } description: {
                Text(Strings.Localizable.noInternetConnection)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        ZStack {
            if viewModel.shouldShowEmptyAlbumView {
                AlbumLinkEmptyView(isLinkRevampEnabled: viewModel.isLinkRevampEnabled)
            } else {
                PhotoLibraryContentView(
                    viewModel: viewModel.photoLibraryContentViewModel,
                    router: PhotoLibraryContentViewRouter(contentMode: .albumLink),
                    onFilterUpdate: nil
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .opacity(viewModel.shouldShowPhotoLibraryContent ? 1.0 : 0)
            }
        }
        .alert(isPresented: $viewModel.showCannotAccessAlbumAlert) {
            Alert(title: Text(Strings.Localizable.AlbumLink.InvalidAlbum.Alert.title),
                  message: Text(Strings.Localizable.AlbumLink.InvalidAlbum.Alert.message),
                  dismissButton: .cancel(Text(Strings.Localizable.AlbumLink.InvalidAlbum.Alert.dissmissButtonTitle),
                                         action: dismissImportAlbumScreen))
        }
        .task {
            await viewModel.loadPublicAlbum()
        }
    }
    
    // MARK: - Toolbars
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            leftNavigationButton
        }
        
        ToolbarItem(placement: .principal) {
            navigationTitle
        }
        
        transferIndicatorToolbarFactory.toolbarContent(trailingItemCount: 1)
        
        ToolbarItem(placement: .topBarTrailing) {
            rightNavigationBarButton
        }
        
        // The revamp's anchored `Save to MEGA` button stands in for the whole bottom bar outside a
        // selection, so the toolbar is only declared where it is still the only thing on offer.
        if !viewModel.showsAnchoredButtons {
            ToolbarItemGroup(placement: .bottomBar) {
                if viewModel.isLinkRevampEnabled {
                    revampedBottomBar
                } else {
                    legacyBottomBar
                }
            }
        }
    }

    /// Download, Save to Photos and Save to MEGA. Share link is not here: the revamped design moves it into
    /// the overflow menu.
    /// Save to MEGA is offered to logged out visitors too, the same as the anchored button this bar stands
    /// in for during a selection: the tap takes them to onboarding rather than to a destination picker.
    @ViewBuilder
    private var revampedBottomBar: some View {
        exportToolbarButton
        Spacer()
        saveToPhotosToolbarButton
        Spacer()
        saveToMEGAToolbarButton
    }

    @ViewBuilder
    private var legacyBottomBar: some View {
        if viewModel.showImportToolbarButton {
            importAlbumToolbarButton
            Spacer()
        }
        saveToPhotosToolbarButton
        Spacer()
        shareLinkButton
    }
    
    @ViewBuilder
    private var leftNavigationButton: some View {
        if viewModel.isSelectionEnabled {
            Button {
                viewModel.selectAllPhotos()
            } label: {
                Image(uiImage: MEGAAssets.UIImage.selectAllItems)
            }
        } else {
            Button {
                dismissImportAlbumScreen()
            } label: {
                closeIcon
            }
            .accessibilityLabel(Strings.Localizable.close)
        }
    }
    
    /// The glass capsule supplies the padding the icon used to draw for itself.
    private var closeIcon: some View {
        MEGAAssets.Image.x
            .frame(width: TokenSpacing._7, height: TokenSpacing._7)
            .foregroundStyle(TokenColors.Icon.primary.swiftUI)
            .padding(isLiquidGlassSupported ? 0 : 10)
    }
    
    @ViewBuilder
    private var navigationTitle: some View {
        if viewModel.isSelectionEnabled {
            NavigationTitleView(title: viewModel.selectionNavigationTitle,
                                isLiquidGlassSupported: isLiquidGlassSupported)
        } else if let albumName = viewModel.publicAlbumName {
            NavigationTitleView(title: albumName,
                                subtitle: Strings.Localizable.albumLink,
                                isLiquidGlassSupported: isLiquidGlassSupported)
        } else {
            NavigationTitleView(title: Strings.Localizable.albumLink,
                                isLiquidGlassSupported: isLiquidGlassSupported)
        }
    }
    
    @ViewBuilder
    private var rightNavigationBarButton: some View {
        if viewModel.isSelectionEnabled {
            Button(Strings.Localizable.cancel) {
                viewModel.enablePhotoLibraryEditMode(false)
            }
        } else if viewModel.shouldShowMoreOptionsButton {
            moreOptionsButton
        } else {
            selectButton
        }
    }
    
    /// The revamp swaps the select button for a more button: selecting is one of the rows of the sheet it
    /// opens, alongside the album's other actions.
    private var moreOptionsButton: some View {
        Button {
            viewModel.showMoreOptions = true
        } label: {
            AlbumLinkMoreOptionsLabel()
                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
        }
        .opacity(moreOptionsButtonOpacity)
        .disabled(viewModel.isMoreOptionsButtonDisabled)
    }
    
    private var moreOptionsButtonOpacity: Double {
        guard !isLiquidGlassSupported else {
            return 1
        }
        return viewModel.isMoreOptionsButtonDisabled ? ImportAlbumViewModel.Constants.disabledOpacity : 1
    }
    
    private var selectButton: some View {
        Button {
            viewModel.enablePhotoLibraryEditMode(true)
        } label: {
            Image(uiImage: MEGAAssets.UIImage.selectAllItems)
        }
        .opacity(selectButtonOpacity)
        // A button faded to nothing still takes taps, and outside the all photos view a tap would
        // put the screen into a selection the year, month and day views have no way to show.
        .disabled(viewModel.isAlbumEmpty || viewModel.selectButtonOpacity == 0)
    }
    
    /// Under Liquid Glass the button carries its own glass capsule, and fading the button fades the
    /// capsule with it. `disabled(_:)` already dims the content there, which leaves the opacity to
    /// do only what the capsule cannot: hide the button outright while the album is still loading.
    private var selectButtonOpacity: Double {
        guard isLiquidGlassSupported else {
            return viewModel.selectButtonOpacity
        }
        return viewModel.selectButtonOpacity > 0 ? 1 : 0
    }
    
    private var isLiquidGlassSupported: Bool {
        if #available(iOS 26.0, *) {
            true
        } else {
            false
        }
    }
    
    private func dismissImportAlbumScreen() {
        viewModel.publicLinkStatus = .none
        invokeDismiss()
    }
    
    // MARK: - Bottom bar buttons
    
    private var importAlbumToolbarButton: some View {
        Button {
            Task { await viewModel.importAlbum() }
        } label: {
            Image(uiImage: MEGAAssets.UIImage.folderArrow)
        }
        .disabled(viewModel.isToolbarButtonsDisabled)
    }

    private var exportToolbarButton: some View {
        Button {
            Task { await viewModel.exportPhotos() }
        } label: {
            Image(uiImage: MEGAAssets.UIImage.arrowDownCircle)
        }
        .disabled(viewModel.isToolbarButtonsDisabled)
        .accessibilityLabel(Strings.Localizable.download)
    }

    /// The revamp's take on `importAlbumToolbarButton`: same action, the icon the design asks for. The design
    /// draws this one inverted, which reads as a slip rather than intent -- nothing else on the screen marks
    /// a primary action that way -- so it carries the same treatment as the two buttons beside it.
    private var saveToMEGAToolbarButton: some View {
        Button {
            Task { await viewModel.importAlbum() }
        } label: {
            Image(uiImage: MEGAAssets.UIImage.uploadToCloud)
        }
        .disabled(viewModel.isToolbarButtonsDisabled)
        .accessibilityLabel(Strings.Localizable.Link.Button.saveToMega)
    }
    
    private var saveToPhotosToolbarButton: some View {
        Button {
            Task { await viewModel.saveToPhotos() }
        } label: {
            Image(uiImage: MEGAAssets.UIImage.photosApp)
        }
        .disabled(viewModel.isToolbarButtonsDisabled)
    }
    
    private var shareLinkButton: some View {
        Button(action: viewModel.shareLinkTapped) {
            Image(uiImage: MEGAAssets.UIImage.link01)
        }
        .disabled(viewModel.isShareLinkButtonDisabled)
    }
}

private extension View {
    func share(isPresented: Binding<Bool>, activityItems: [Any]) -> some View {
        background(
            ShareSheet(isPresented: isPresented, activityItems: activityItems)
        )
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let activityItems: [Any]
    
    final class Coordinator {
        var shareSheet: UIActivityViewController?
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard context.coordinator.shareSheet == nil, isPresented else { return }
        
        let shareSheet = UIActivityViewController(activityItems: activityItems,
                                                  applicationActivities: nil)
        context.coordinator.shareSheet = shareSheet
        shareSheet.popoverPresentationController?.sourceView = uiViewController.view
        
        shareSheet.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
            context.coordinator.shareSheet = nil
        }
        uiViewController.present(shareSheet, animated: true)
    }
}
