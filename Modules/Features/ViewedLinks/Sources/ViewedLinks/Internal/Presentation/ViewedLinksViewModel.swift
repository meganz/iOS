import Combine
import Foundation
import MEGAL10n
import MEGASwift
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI

@MainActor
final class ViewedLinksViewModel: ObservableObject {
    @Published var editMode: EditMode = .inactive
    @Published var isPresentingClearSelectedConfirmation = false
    @Published var isPresentingClearAllConfirmation = false
    @Published private(set) var selectedIds: Set<ResultId> = []

    private(set) var clearedSnackBarMessage: String?

    var clearSelectedLinksTitle: String {
        selectedIds.count == 1
            ? Strings.Localizable.ViewedLinks.ClearLink.Confirmation.title
            : Strings.Localizable.ViewedLinks.ClearLinks.Confirmation.title
    }

    var selectionTitle: String {
        guard selectedIds.isNotEmpty else { return Strings.Localizable.selectTitle }
        return Strings.Localizable.General.Format.itemsSelected(selectedIds.count)
    }

    lazy var searchResultsContainerViewModel: SearchResultsContainerViewModel = {
        let searchBridge = makeSearchBridge()
        let searchConfig = SearchConfig.viewedLinks

        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: resultsProvider,
            bridge: searchBridge,
            config: searchConfig,
            layout: .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .unknown,
            listHeaderViewModel: nil,
            isSelectionEnabled: true,
            contentUnavailableViewModelProvider: ViewedLinksContentUnavailableProvider()
        )

        return SearchResultsContainerViewModel(
            bridge: searchBridge,
            config: searchConfig,
            searchResultsViewModel: searchResultsViewModel,
            sortHeaderConfig: .viewedLinks,
            headerType: .dynamic,
            initialViewMode: viewMode,
            shouldShowMediaDiscoveryModeHandler: { false },
            sortHeaderViewPressedEvent: { }
        )
    }()

    private let viewedLinksUseCase: any ViewedLinksUseCaseProtocol
    private let openLink: @MainActor (URL) -> Void
    private let resultsProvider: ViewedLinksSearchResultsProvider
    private static let defaultSortOrder = MEGAUIComponent.SortOrder(key: .name)

    private var sortOrder = defaultSortOrder
    private var viewMode: SearchResultsViewMode = .list
    private var subscriptions: Set<AnyCancellable> = []

    init(
        viewedLinksUseCase: some ViewedLinksUseCaseProtocol,
        thumbnailUseCase: some ViewedLinkThumbnailUseCaseProtocol,
        openLink: @escaping @MainActor (URL) -> Void
    ) {
        self.viewedLinksUseCase = viewedLinksUseCase
        self.openLink = openLink
        resultsProvider = ViewedLinksSearchResultsProvider(
            viewedLinksUseCase: viewedLinksUseCase,
            mapper: ViewedLinkSearchResultMapper(thumbnailUseCase: thumbnailUseCase)
        )
        listenToEditingChanges()
    }

    func requestClearSelectedLinks() {
        guard selectedIds.isNotEmpty else { return }
        isPresentingClearSelectedConfirmation = true
    }

    func requestClearAllLinks() {
        isPresentingClearAllConfirmation = true
    }

    /// Removes the selected links once the store has accepted the change.
    /// - Returns: `true` when nothing is left, so the caller can close the screen.
    func clearSelectedLinks() async -> Bool {
        let links = resultsProvider.links(for: selectedIds)
        guard links.isNotEmpty else { return false }

        let clearsEverything = links.count == resultsProvider.currentResultIds().count

        do {
            try await viewedLinksUseCase.remove(links)
        } catch {
            return false
        }

        guard clearsEverything else {
            exitEditMode()
            return false
        }

        clearedSnackBarMessage = Strings.Localizable.ViewedLinks.Clear.Success.message
        return true
    }

    /// Clears the whole history once the store has accepted the change.
    /// - Returns: `true` when nothing is left, so the caller can close the screen.
    func clearAllLinks() async -> Bool {
        do {
            try await viewedLinksUseCase.clearHistory()
        } catch {
            return false
        }

        clearedSnackBarMessage = Strings.Localizable.ViewedLinks.Clear.Success.message
        return true
    }

    func exitEditMode() {
        withAnimation {
            editMode = .inactive
        }
    }

    // MARK: - Private methods

    private func makeSearchBridge() -> SearchBridge {
        let searchBridge = SearchBridge(
            selection: { [weak self] selection in
                guard let self, let link = resultsProvider.link(for: selection.result.id) else { return }
                openLink(link.linkURL)
            },
            context: { _, _ in },
            chipTapped: { _, _ in },
            sortingOrder: { [weak self] in
                self?.sortOrder ?? Self.defaultSortOrder
            },
            updateSortOrder: { [weak self] sortOrder in
                self?.sortOrder = sortOrder
            },
            chipPickerShowedHandler: { _ in }
        )

        // Deferred because the container view model emits its initial view mode from inside its
        // own initializer, which still runs inside the lazy property this bridge belongs to.
        searchBridge.viewModeChanged = { [weak self] viewMode in
            Task { @MainActor in
                self?.viewModeDidChange(viewMode)
            }
        }

        searchBridge.editingChanged = { [weak self] editing in
            self?.editMode = editing ? .active : .inactive
        }

        searchBridge.selectionChanged = { [weak self] ids in
            self?.selectedIds = ids
        }

        return searchBridge
    }

    private func viewModeDidChange(_ viewMode: SearchResultsViewMode) {
        guard self.viewMode != viewMode else { return }
        self.viewMode = viewMode
        switch viewMode {
        case .grid:
            searchResultsContainerViewModel.update(pageLayout: .thumbnail)
        case .list:
            searchResultsContainerViewModel.update(pageLayout: .list)
        case .mediaDiscovery:
            break // Media discovery is not supported in viewed links
        }
    }

    /// `SearchResultsViewModel.clearSelection()` does not report back through the bridge, and the
    /// sink that would is throttled, so the selection is reset here as well.
    private func listenToEditingChanges() {
        $editMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] mode in
                guard let self else { return }
                let isEditing = mode.isEditing
                searchResultsContainerViewModel.setEditing(isEditing)
                if !isEditing {
                    searchResultsContainerViewModel.clearSelection()
                    selectedIds = []
                }
            }
            .store(in: &subscriptions)
    }
}
