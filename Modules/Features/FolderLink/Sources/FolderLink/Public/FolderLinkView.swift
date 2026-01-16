import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import Search
import SwiftUI

public struct FolderLinkView<LinkUnavailable>: View where LinkUnavailable: View {
    public struct Dependency {
        let link: String
        let folderLinkBuilder: any FolderLinkBuilderProtocol
        let searchResultMapper: any FolderLinkSearchResultMapperProtocol
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let fileNodeOpener: any FolderLinkFileNodeOpenerProtocol
        let nodeActionHandler: any FolderLinkNodeActionHandlerProtocol
        let onClose: @MainActor () -> Void
        
        public init(
            link: String,
            folderLinkBuilder: some FolderLinkBuilderProtocol,
            searchResultMapper: some FolderLinkSearchResultMapperProtocol,
            sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
            fileNodeOpener: some FolderLinkFileNodeOpenerProtocol,
            nodeActionHandler: some FolderLinkNodeActionHandlerProtocol,
            onClose: @escaping @MainActor () -> Void
        ) {
            self.link = link
            self.folderLinkBuilder = folderLinkBuilder
            self.searchResultMapper = searchResultMapper
            self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
            self.fileNodeOpener = fileNodeOpener
            self.nodeActionHandler = nodeActionHandler
            self.onClose = onClose
        }
    }
    
    enum NavigationRoute: Hashable {
        case folder(HandleEntity)
    }
    
    @StateObject private var viewModel: FolderLinkViewModel
    @State private var navigationPath = NavigationPath()
    
    private let dependency: Dependency
    @ViewBuilder let linkUnavailableContent: (LinkUnavailableReason) -> LinkUnavailable
    
    public init(
        dependency: Dependency,
        @ViewBuilder linkUnavailableContent: @escaping (LinkUnavailableReason) -> LinkUnavailable
    ) {
        self.dependency = dependency
        self.linkUnavailableContent = linkUnavailableContent
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
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        closeButton
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text(Strings.Localizable.folderLink)
                            .font(.headline)
                            .foregroundStyle(TokenColors.Text.primary.swiftUI)
                            .lineLimit(1)
                    }
                }
        case let .error(reason):
            linkUnavailableContent(reason)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        closeButton
                    }
                    
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text(Strings.Localizable.folderLink)
                                .font(.headline)
                                .foregroundStyle(TokenColors.Text.primary.swiftUI)
                                .lineLimit(1)
                            Text(Strings.Localizable.unavailable)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                                .lineLimit(1)
                        }
                    }
                }
        case let .results(nodeHandle):
            FolderLinkResultsView(
                dependency: folderLinkResultsDependency(isRoot: true, handle: nodeHandle)
            )
        }
    }
    
    @ViewBuilder
    private func navigationDestinationBuilder(with route: NavigationRoute) -> some View {
        switch route {
        case let .folder(nodeHandle):
            FolderLinkResultsView(
                dependency: folderLinkResultsDependency(isRoot: false, handle: nodeHandle)
            )
        }
    }
    
    private var closeButton: some View {
        Button {
            viewModel.stopLoadingFolderLink()
            dependency.onClose()
        } label: {
            Text(Strings.Localizable.close)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }
    }
    
    private func folderLinkResultsDependency(isRoot: Bool, handle: HandleEntity) -> FolderLinkResultsView.Dependency {
        FolderLinkResultsView.Dependency(
            isRoot: isRoot,
            handle: handle,
            link: dependency.link,
            searchResultMapper: dependency.searchResultMapper,
            sortOrderPreferenceUseCase: dependency.sortOrderPreferenceUseCase,
            nodeActionHandler: dependency.nodeActionHandler,
            selectionHandler: { selection in
                if selection.result.isFolder {
                    navigationPath.append(NavigationRoute.folder(selection.result.id))
                } else {
                    dependency.fileNodeOpener.openNode(handle: selection.result.id, siblings: selection.siblings())
                }
            },
            onDismiss: { isRoot in
                if isRoot {
                    dependency.onClose()
                } else {
                    navigationPath.removeLast()
                }
            }
        )
    }
}
