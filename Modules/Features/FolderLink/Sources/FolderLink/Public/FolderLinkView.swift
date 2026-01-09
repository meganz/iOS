import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import Search
import SwiftUI

public struct FolderLinkView: View {
    public struct Dependency {
        let link: String
        let folderLinkBuilder: any FolderLinkBuilderProtocol
        let searchResultMapper: any FolderLinkSearchResultMapperProtocol
        let fileNodeOpener: any FolderLinkFileNodeOpenerProtocol
        let onClose: @MainActor () -> Void
        
        public init(
            link: String,
            folderLinkBuilder: some FolderLinkBuilderProtocol,
            searchResultMapper: some FolderLinkSearchResultMapperProtocol,
            fileNodeOpener: some FolderLinkFileNodeOpenerProtocol,
            onClose: @escaping @MainActor () -> Void
        ) {
            self.link = link
            self.folderLinkBuilder = folderLinkBuilder
            self.searchResultMapper = searchResultMapper
            self.fileNodeOpener = fileNodeOpener
            self.onClose = onClose
        }
    }
    
    enum NavigationRoute: Hashable {
        case folder(HandleEntity)
    }
    
    @StateObject private var viewModel: FolderLinkViewModel
    @State private var navigationPath = NavigationPath()
    
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
        NavigationStack(path: $navigationPath) {
            content
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbarRole(.editor)
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
                    
                    ToolbarItem(placement: .principal) {
                        Text(Strings.Localizable.folderLink)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                .navigationDestination(for: NavigationRoute.self) { route in
                    navigationDestinationBuilder(with: route)
                }
        }
        .tint(TokenColors.Icon.primary.swiftUI)
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
                .askingForDecryptionKeyAlert(
                    isPresented: $viewModel.askingForDecryptionKey,
                    confirm: { text in
                        Task {
                            await viewModel.confirmDecryptionKey(text)
                        }
                    }, cancel: {
                        viewModel.cancelConfirmingDecryptionKey()
                        dependency.onClose()
                    }
                )
                .invalidDecryptionKeyAlert(isPresented: $viewModel.notifyInvalidDecryptionKey) {
                    viewModel.acknowledgeInvalidDecryptionKey()
                }
        case .error:
            // IOS-11082
            Text("Error")
        case let .results(nodeHandle):
            folderLinkResultsView(for: nodeHandle)
        }
    }
    
    private func folderLinkResultsView(for nodeHandle: HandleEntity) -> some View {
        FolderLinkResultsView(
            dependency: folderLinkResultsDependency(handle: nodeHandle)
        )
    }
    
    @ViewBuilder
    private func navigationDestinationBuilder(with route: NavigationRoute) -> some View {
        switch route {
        case let .folder(nodeHandle):
            FolderLinkResultsView(
                dependency: folderLinkResultsDependency(handle: nodeHandle)
            )
        }
    }
    
    private func folderLinkResultsDependency(handle: HandleEntity) -> FolderLinkResultsView.Dependency {
        FolderLinkResultsView.Dependency(
            handle: handle,
            searchResultMapper: dependency.searchResultMapper,
            selectionHandler: { selection in
                if selection.result.isFolder {
                    navigationPath.append(NavigationRoute.folder(selection.result.id))
                } else {
                    dependency.fileNodeOpener.openNode(handle: selection.result.id, siblings: selection.siblings())
                }
            }
        )
    }
}
