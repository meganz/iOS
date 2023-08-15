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
                
                PhotoLibraryContentView(
                    viewModel: viewModel.photoLibraryContentViewModel,
                    router: PhotoLibraryContentViewRouter(contentMode: .albumLink),
                    onFilterUpdate: nil
                )
                .opacity(viewModel.isPhotosLoaded ? 1.0 : 0)
                
                Spacer()
                
                if viewModel.showSnackBar {
                    SnackBarView(viewModel: viewModel.snackBarViewModel())
                }
                
                bottomToolbar
            }
        }
        .taskForiOS14 {
            await viewModel.loadPublicAlbum()
        }
        .alert(isPresented: $viewModel.showRenameAlbumAlert,
               viewModel.renameAlbumAlertViewModel())
        .alert(isPresented: $viewModel.showCannotAccessAlbumAlert) {
            Alert(title: Text(Strings.Localizable.AlbumLink.InvalidAlbum.Alert.title),
                  message: Text(Strings.Localizable.AlbumLink.InvalidAlbum.Alert.message),
                  dismissButton: .cancel(Text(Strings.Localizable.AlbumLink.InvalidAlbum.Alert.dissmissButtonTitle),
                                          action: dismissImportAlbumScreen))
        }
        .sheet(isPresented: $viewModel.showImportAlbumLocation) {
            BrowserView(browserAction: .saveToCloudDrive,
                        isChildBrowser: true,
                        parentNode: MEGASdk.shared.rootNode,
                        selectedNode: $viewModel.importFolderLocation)
                .ignoresSafeArea(edges: .bottom)
        }
        .fullScreenCover(isPresented: $viewModel.showStorageQuotaWillExceed) {
            CustomModalAlertView(mode: .storageQuotaWillExceed(displayMode: .albumLink))
        }
        .onAppear { viewModel.onViewAppear() }
        .onReceive(viewModel.$showLoading.dropFirst()) {
            $0 ? SVProgressHUD.show() : SVProgressHUD.dismiss()
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
        }, backgroundColor: Color(Colors.General.Gray.navigationBgColor.color))
    }
    
    @ViewBuilder
    private var leftNavigationButton: some View {
        if viewModel.isSelectionEnabled {
            Button {
                viewModel.selectAllPhotos()
            } label: {
                Image(uiImage: Asset.Images.NavigationBar.selectAll.image)
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
                Image(uiImage: Asset.Images.NavigationBar.selectAll.image)
            }
            .opacity(viewModel.selectButtonOpacity)
            .disabled(!viewModel.isPhotosLoaded)
        }
    }
    
    private var toolbarButtonColor: Color {
        colorScheme == .dark ? Color(Colors.General.Gray.d1D1D1.color) : Color(Colors.General.Gray._515151.color)
    }
    
    private func dismissImportAlbumScreen() {
        viewModel.publicLinkStatus = .none
        presentationMode.wrappedValue.dismiss()
    }
    
    private var bottomToolbar: some View {
        HStack(alignment: .top) {
            if viewModel.showImportToolbarButton {
                toolbarImageButton(image: Asset.Images.InfoActions.import.image) {
                    Task { await viewModel.importAlbum() }
                }
                Spacer()
            }
            toolbarImageButton(image: Asset.Images.NodeActions.saveToPhotos.image) {
                
            }
            Spacer()
            shareLinkButton()
        }
        .frame(maxHeight: 64)
        .background(Color(Colors.General.Gray.navigationBgColor.color)
            .edgesIgnoringSafeArea(.bottom))
    }
    
    private func toolbarImageButton(image: UIImage, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(uiImage: image)
                .resizable()
                .frame(width: 28, height: 28)
                .opacity(toolbarButtonOpacity)
        }
        .disabled(viewModel.isToolbarButtonsDisabled)
        .padding(.vertical, Constants.toolbarButtonVerticalPadding)
        .padding(.horizontal, Constants.toolbarButtonHorizontalPadding)
    }
    
    @ViewBuilder
    private func shareLinkButton() -> some View {
        if #available(iOS 16.0, *) {
            ShareLink(item: viewModel.publicLink) {
                Image(uiImage: Asset.Images.Generic.link.image)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .opacity(toolbarButtonOpacity)
            }
            .padding(.vertical, Constants.toolbarButtonVerticalPadding)
            .padding(.horizontal, Constants.toolbarButtonHorizontalPadding)
            .disabled(viewModel.isToolbarButtonsDisabled)
        } else {
            toolbarImageButton(image: Asset.Images.Generic.link.image,
                               action: viewModel.shareLinkTapped)
            .share(isPresented: $viewModel.showShareLink, activityItems: [viewModel.publicLink])
        }
    }
    
    private var toolbarButtonOpacity: Double {
        viewModel.isToolbarButtonsDisabled ? ImportAlbumViewModel.Constants.disabledOpacity : 1
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
