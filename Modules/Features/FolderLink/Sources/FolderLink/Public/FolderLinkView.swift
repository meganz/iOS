import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct FolderLinkView: View {
    public struct Dependency {
        let link: String
        let folderLinkBuilder: any FolderLinkBuilderProtocol
        let onClose: @MainActor () -> Void
        
        public init(
            link: String,
            folderLinkBuilder: some FolderLinkBuilderProtocol,
            onClose: @escaping @MainActor () -> Void
        ) {
            self.link = link
            self.folderLinkBuilder = folderLinkBuilder
            self.onClose = onClose
        }
    }
    
    @StateObject private var viewModel: FolderLinkViewModel
    private let dependency: Dependency
    
    public init(dependency: Dependency) {
        self.dependency = dependency
        _viewModel = StateObject(
            wrappedValue: FolderLinkViewModel(
                dependency: FolderLinkViewModel.Dependency(
                    link: dependency.link,
                    folderLinkBuilder: dependency.folderLinkBuilder
                )
            )
        )
    }
    
    public var body: some View {
        NavigationStack {
            content
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(Strings.Localizable.folderLink)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewModel.stopLoadingFolderLink()
                            dependency.onClose()
                        } label: {
                            Text(Strings.Localizable.close)
                                .font(.body)
                                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            ProgressView()
                .opacity(viewModel.askingForDecryptionKey || viewModel.notifyInvalidDecryptionKey ? 0 : 1)
                .onFirstLoad {
                    await viewModel.startLoadingFolderLink()
                }
                .alert(isPresented: $viewModel.askingForDecryptionKey, askingForDecryptionKeyAlertViewModel)
                .alert(
                    Strings.Localizable.decryptionKeyNotValid,
                    isPresented: $viewModel.notifyInvalidDecryptionKey, actions: {
                        Button(Strings.Localizable.ok) {
                            viewModel.acknowledgeInvalidDecryptionKey()
                        }
                    }
                )
        case .error:
            // IOS-11082
            Text("Error")
        case let .results(handleEntity):
            // IOS-11075
            Text("Results: \(handleEntity)")
        }
    }
    
    private var askingForDecryptionKeyAlertViewModel: TextFieldAlertViewModel {
        TextFieldAlertViewModel(
            title: Strings.Localizable.decryptionKeyAlertTitle,
            placeholderText: Strings.Localizable.decryptionKey,
            affirmativeButtonTitle: Strings.Localizable.decrypt,
            affirmativeButtonInitiallyEnabled: false,
            destructiveButtonTitle: Strings.Localizable.cancel,
            message: Strings.Localizable.decryptionKeyAlertMessage,
            action: { text in
                if let text {
                    Task {
                        await viewModel.confirmDecryptionKey(text)
                    }
                } else {
                    viewModel.cancelConfirmingDecryptionKey()
                    dependency.onClose()
                }
            },
            validator: { text in
                if let text, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    nil
                } else {
                    TextFieldAlertError(title: "", description: "")
                }
            }
        )
    }
}
