import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import Search
import SwiftUI

public struct FavouritesView: View {
    public struct Dependency {
        let fileSearchUseCase: any FilesSearchUseCaseProtocol
        let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
        let searchResultsMapper: any FavouritesSearchResultsMapping
        let downloadedNodesListener: any DownloadedNodesListening
        let nodeUseCase: any NodeUseCaseProtocol
        let contextAction: @MainActor (HandleEntity, UIButton) -> Void
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
        let nodesActionHandler: any NodesActionHandling
        let onEditingChanged: @MainActor (Bool) -> Void

        public init(
            fileSearchUseCase: some FilesSearchUseCaseProtocol,
            sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
            searchResultsMapper: some FavouritesSearchResultsMapping,
            downloadedNodesListener: some DownloadedNodesListening,
            nodeUseCase: some NodeUseCaseProtocol,
            contextAction: @escaping @MainActor (HandleEntity, UIButton) -> Void,
            sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol,
            nodesActionHandler: some NodesActionHandling,
            onEditingChanged: @escaping @MainActor (Bool) -> Void
        ) {
            self.fileSearchUseCase = fileSearchUseCase
            self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
            self.searchResultsMapper = searchResultsMapper
            self.downloadedNodesListener = downloadedNodesListener
            self.nodeUseCase = nodeUseCase
            self.contextAction = contextAction
            self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
            self.nodesActionHandler = nodesActionHandler
            self.onEditingChanged = onEditingChanged
        }
    }

    @StateObject private var viewModel: FavouritesViewModel
    private let dependency: Dependency

    public init(dependency: Dependency) {
        _viewModel = StateObject(
            wrappedValue: FavouritesViewModel(
                dependency: .init(
                    resultsProvider: FavouriteSearchResultsProvider(
                        dependency: .init(
                            fileSearchUseCase: dependency.fileSearchUseCase,
                            sensitiveDisplayPreferenceUseCase: dependency.sensitiveDisplayPreferenceUseCase,
                            searchResultsMapper: dependency.searchResultsMapper,
                            downloadedNodesListener: dependency.downloadedNodesListener,
                            nodeUseCase: dependency.nodeUseCase
                        )
                    ),
                    contextAction: dependency.contextAction,
                    sortOrderPreferenceUseCase: dependency.sortOrderPreferenceUseCase
                )
            )
        )
        self.dependency = dependency
    }

    public var body: some View {
        VStack(spacing: 0) {
            SearchBarView(
                text: $viewModel.searchText,
                isEditing: $viewModel.searchBecameActive,
                placeholder: Strings.Localizable.search,
                cancelTitle: Strings.Localizable.cancel
            )
            .padding(TokenSpacing._3)
            .background(TokenColors.Background.surface1.swiftUI)

            SearchResultsContainerView(viewModel: viewModel.searchResultsContainerViewModel)
        }
        .background(TokenColors.Background.page.swiftUI)
        .navigationTitle(viewModel.editMode.isEditing ? selectionTitle : Strings.Localizable.Home.Favourites.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.editMode.isEditing)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if viewModel.editMode.isEditing {
                    Button {
                        viewModel.toggleSelectAll()
                    } label: {
                        Label {
                            Text(Strings.Localizable.selectAll)
                        } icon: {
                            MEGAAssets.Image.checkStack
                                .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        }
                        .labelStyle(.iconOnly)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.editMode.isEditing {
                    Button(Strings.Localizable.cancel) {
                        viewModel.exitEditMode()
                    }
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if viewModel.editMode.isEditing {
                    bottomBar
                        .disabled(viewModel.bottomBarDisabled)
                }
            }
        }
        .environment(\.editMode, $viewModel.editMode)
        .onChange(of: viewModel.editMode) { editMode in
            dependency.onEditingChanged(editMode.isEditing)
        }
        .onReceive(viewModel.$nodesAction.compactMap { $0 }) { action in
            dependency.nodesActionHandler.handle(action: action)
            viewModel.exitEditMode()
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        BottomBarActionButton(action: .download, selection: $viewModel.bottomBarAction)
        Spacer()
        BottomBarActionButton(action: .removeFavourite, selection: $viewModel.bottomBarAction)
        Spacer()
        BottomBarActionButton(action: .shareLink, selection: $viewModel.bottomBarAction)
        Spacer()
        BottomBarActionButton(action: .moveToRubbishBin, selection: $viewModel.bottomBarAction)
        Spacer()
        BottomBarActionButton(action: .more, selection: $viewModel.bottomBarAction)
    }

    private var selectionTitle: String {
        let count = viewModel.selectedNodeHandles.count
        guard count > 0 else {
            return Strings.Localizable.selectTitle
        }
        return Strings.Localizable.General.Format.itemsSelected(count)
    }
}
