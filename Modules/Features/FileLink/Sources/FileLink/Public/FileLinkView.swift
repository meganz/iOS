import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

/// Entry point of the file link screen. It owns the access flow only: the screen is on top before the
/// link is resolved, shows the skeleton while that happens, asks for a decryption key when the link
/// was shared without one, and shows the unavailable state when the link cannot be opened.
public struct FileLinkView<LinkUnavailable>: View where LinkUnavailable: View {
    public struct Dependency {
        let link: String
        let fileLinkBuilder: any FileLinkBuilderProtocol
        let onClose: @MainActor () -> Void

        public init(
            link: String,
            fileLinkBuilder: some FileLinkBuilderProtocol,
            onClose: @escaping @MainActor () -> Void
        ) {
            self.link = link
            self.fileLinkBuilder = fileLinkBuilder
            self.onClose = onClose
        }
    }

    @StateObject private var viewModel: FileLinkViewModel

    private let dependency: Dependency
    @ViewBuilder let linkUnavailableContent: (LinkUnavailableReason) -> LinkUnavailable

    public init(
        dependency: Dependency,
        @ViewBuilder linkUnavailableContent: @escaping (LinkUnavailableReason) -> LinkUnavailable
    ) {
        self.dependency = dependency
        self.linkUnavailableContent = linkUnavailableContent
        _viewModel = StateObject(
            wrappedValue: FileLinkViewModel(
                dependency: FileLinkViewModel.Dependency(
                    link: dependency.link,
                    fileLinkBuilder: dependency.fileLinkBuilder
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
            // Placeholder for the revamped content page. Naming the file is enough to tell that the
            // link resolved; the preview, the size and the actions arrive with that page.
            Text(node.name)
                .font(.callout)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .padding(TokenSpacing._5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(TokenColors.Background.page.swiftUI)
                .toolbar { toolbarContent }
        case let .error(reason):
            linkUnavailableContent(reason)
                .ignoresSafeArea()
                .toolbar { toolbarContent }
        }
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

    @ViewBuilder
    private var titleView: some View {
        VStack {
            Text(Strings.Localizable.fileLink)
                .font(.headline)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                .lineLimit(1)

            if case .error = viewModel.viewState {
                Text(Strings.Localizable.unavailable)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .lineLimit(1)
            }
        }
    }

    private var closeButton: some View {
        Button {
            viewModel.stopLoadingFileLink()
            dependency.onClose()
        } label: {
            Text(Strings.Localizable.close)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
    }
}
