import MEGASwiftUI
import SwiftUI

struct ImportAlbumView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject var viewModel: ImportAlbumViewModel
    
    var body: some View {
        ZStack {
            EmptyView()
                .decryptionKeyMissingAlert(isPresented: $viewModel.showingDecryptionKeyAlert,
                                           decryptionKey: $viewModel.publicLinkDecryptionKey,
                                           onTappingCancel: dismissImportAlbumScreen)
            VStack {
                navigationBar
                Spacer()
            }
        }
        .onReceive(viewModel.$publicLinkStatus, perform: { status in
            status == .inProgress ? SVProgressHUD.show() : SVProgressHUD.dismiss()
        })
    }
    
    private var buttonClose: some View {
        Button(Strings.Localizable.close) {
            dismissImportAlbumScreen()
        }
        .foregroundColor(closeButton)
    }
    
    private var closeButton: Color {
        Color(colorScheme == .dark ? .mnz_grayD1D1D1() : .mnz_gray515151())
    }
    
    private var titleTextColor: Color {
        Color(colorScheme == .dark ? .white : .black)
    }
    
    private var navigationBar: some View {
        NavigationBarView(leading: {
            buttonClose
        }, trailing: {
            Text("")
        }, center: {
            Text(Strings.Localizable.albumLink)
                .foregroundColor(titleTextColor)
                .bold()
        }, backgroundColor: Color(Colors.General.Gray.navigationBgColor.color))
    }
    
    private func dismissImportAlbumScreen() {
        viewModel.publicLinkStatus = .none
        presentationMode.wrappedValue.dismiss()
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
}
