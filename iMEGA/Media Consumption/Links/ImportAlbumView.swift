import ContentLibraries
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ImportAlbumView: View {
    private enum Constants {
        static let toolbarButtonVerticalPadding = 11.0
        static let toolbarButtonHorizontalPadding = 16.0
    }
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject var viewModel: ImportAlbumViewModel
    var invokeDismiss: (() -> Void)?
    
    @State private var publicAlbumLoadingTask: Task<Void, Never>?
    
    var body: some View {
        
        ZStack {
            EmptyView()
                .decryptionKeyMissingAlert(isPresented: $viewModel.showingDecryptionKeyAlert,
                                           decryptionKey: $viewModel.publicLinkDecryptionKey,
                                           onTappingCancel: dismissImportAlbumScreen,
                                           onTappingDecryptButton: {
                    publicAlbumLoadingTask = Task {
                        await viewModel.loadWithNewDecryptionKey()
                    }
                })
            
            VStack(spacing: 0) {
                navigationBar
                
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
                    .frame(maxHeight: .infinity)
                }
                
                bottomToolbar
            }
            .task {
                viewModel.monitorNetworkConnection()
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
    
    @ViewBuilder
    private func content() -> some View {
        ZStack {
            if viewModel.shouldShowEmptyAlbumView {
                ContentUnavailableView {
                    MEGAAssets.Image.allPhotosEmptyState
                } description: {
                    Text(Strings.Localizable.CameraUploads.Albums.Empty.title)
                        .font(.body)
                }
                .frame(maxHeight: .infinity)
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
    
    private var navigationBar: some View {
        NavigationBarView(leading: {
            leftNavigationButton
        }, trailing: {
            rightNavigationBarButton
                .frame(maxHeight: 44)
        }, center: {
            navigationTitle
        }, backgroundColor: TokenColors.Background.surface1.swiftUI)
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
            Button(Strings.Localizable.close) {
                dismissImportAlbumScreen()
            }
            .foregroundColor(toolbarButtonColor)
        }
    }
    
    @ViewBuilder
    private var navigationTitle: some View {
        if viewModel.isSelectionEnabled {
            NavigationTitleView(title: viewModel.selectionNavigationTitle)
        } else if let albumName = viewModel.publicAlbumName {
            NavigationTitleView(title: albumName, subtitle: Strings.Localizable.albumLink)
        } else {
            NavigationTitleView(title: Strings.Localizable.albumLink)
        }
    }
    
    @ViewBuilder
    private var rightNavigationBarButton: some View {
        if viewModel.isSelectionEnabled {
            Button {
                viewModel.enablePhotoLibraryEditMode(false)
            } label: {
                Text(Strings.Localizable.cancel)
                    .font(.body)
                    .foregroundColor(toolbarButtonColor)
            }
        } else {
            Button {
                viewModel.enablePhotoLibraryEditMode(true)
            } label: {
                Image(uiImage: MEGAAssets.UIImage.selectAllItems)
            }
            .opacity(viewModel.selectButtonOpacity)
            .disabled(viewModel.isAlbumEmpty)
        }
    }
    
    private var toolbarButtonColor: Color {
        TokenColors.Text.primary.swiftUI
    }
    
    private func dismissImportAlbumScreen() {
        viewModel.publicLinkStatus = .none
        presentationMode.wrappedValue.dismiss()
    }
    
    private var bottomToolbar: some View {
        HStack(alignment: .top) {
            if viewModel.showImportToolbarButton {
                importAlbumToolbarButton()
                Spacer()
            }
            saveToPhotosToolbarButton()
            Spacer()
            shareLinkButton()
        }
        .frame(maxHeight: 64)
        .background(TokenColors.Background.surface1.swiftUI.edgesIgnoringSafeArea(.bottom))
    }
    
    private func importAlbumToolbarButton() -> some View {
        ToolbarImageButton(image: MEGAAssets.UIImage.import,
                           isDisabled: viewModel.isToolbarButtonsDisabled,
                           action: {
            Task { await viewModel.importAlbum() }
        })
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
    }
    
    private func saveToPhotosToolbarButton() -> some View {
        ToolbarImageButton(image: MEGAAssets.UIImage.saveToPhotos,
                           isDisabled: viewModel.isToolbarButtonsDisabled,
                           action: {
            Task { await viewModel.saveToPhotos() }
        })
        .alertPhotosPermission(isPresented: $viewModel.showPhotoPermissionAlert)
    }
    
    private func shareLinkButton() -> some View {
        ToolbarImageButton(
            image: MEGAAssets.UIImage.link,
            isDisabled: viewModel.isShareLinkButtonDisabled,
            action: viewModel.shareLinkTapped)
        .share(isPresented: $viewModel.showShareLink, activityItems: [viewModel.publicLink])
    }
}

private extension View {
    func decryptionKeyMissingAlert(
        isPresented: Binding<Bool>,
        decryptionKey: Binding<String>,
        onTappingCancel: (() -> Void)? = nil,
        onTappingDecryptButton: (() -> Void)? = nil
    ) -> some View {
        ImportAlbumAlertView(
            textString: decryptionKey,
            showingAlert: isPresented,
            title: Strings.Localizable.decryptionKeyAlertTitle,
            message: Strings.Localizable.decryptionKeyAlertMessageForAlbum,
            placeholderText: "",
            cancelButtonText: Strings.Localizable.cancel,
            decryptButtonText: Strings.Localizable.decrypt,
            onTappingCancelButton: onTappingCancel,
            onTappingDecryptButton: onTappingDecryptButton
        )
    }
    
    func share(isPresented: Binding<Bool>, activityItems: [Any]) -> some View {
        background(
            ShareSheet(isPresented: isPresented, activityItems: activityItems)
        )
    }
}

private struct ToolbarImageButton: View {
    private enum Constants {
        static let toolbarButtonVerticalPadding = 11.0
        static let toolbarButtonHorizontalPadding = 16.0
        static let disabledOpacity = 0.3
        static let imageSize: CGSize = .init(width: 28, height: 28)
    }
    
    let image: UIImage
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(uiImage: image)
                .resizable()
                .frame(width: Constants.imageSize.width,
                       height: Constants.imageSize.height)
                .opacity(toolbarButtonOpacity)
        }
        .disabled(isDisabled)
        .padding(.vertical, Constants.toolbarButtonVerticalPadding)
        .padding(.horizontal, Constants.toolbarButtonHorizontalPadding)
    }
    
    private var toolbarButtonOpacity: Double {
        isDisabled ? Constants.disabledOpacity : 1
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
