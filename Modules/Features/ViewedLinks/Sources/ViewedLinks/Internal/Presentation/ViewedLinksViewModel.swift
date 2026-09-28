import Combine
import Foundation
import MEGAFoundation
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

    var navigationTitle: String {
        editMode.isEditing ? selectionTitle : Strings.Localizable.Home.Customization.Widget.viewedLinks
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

    private static let defaultSortOrder = MEGAUIComponent.SortOrder(key: .dateAdded, direction: .descending)
    private static let clearSuccessMessage = Strings.Localizable.ViewedLinks.Clear.Success.message

    private let viewedLinksUseCase: any ViewedLinksUseCaseProtocol
    private let openLink: @MainActor (URL) -> Void
    private let resultsProvider: any ViewedLinksResultsProviding

    private var sortOrder = defaultSortOrder
    private var viewMode: SearchResultsViewMode = .list
    private var subscriptions: Set<AnyCancellable> = []

    convenience init(
        viewedLinksUseCase: some ViewedLinksUseCaseProtocol = ViewedLinksFactory.makeViewedLinksUseCase(),
        thumbnailUseCase: some ViewedLinkThumbnailUseCaseProtocol = ViewedLinksFactory.makeViewedLinkThumbnailUseCase(),
        openLink: @escaping @MainActor (URL) -> Void
    ) {
        self.init(
            viewedLinksUseCase: viewedLinksUseCase,
            resultsProvider: ViewedLinksSearchResultsProvider(
                viewedLinksUseCase: viewedLinksUseCase,
                mapper: ViewedLinkSearchResultMapper(thumbnailUseCase: thumbnailUseCase)
            ),
            openLink: openLink
        )
    }

    init(
        viewedLinksUseCase: some ViewedLinksUseCaseProtocol,
        resultsProvider: some ViewedLinksResultsProviding,
        openLink: @escaping @MainActor (URL) -> Void
    ) {
        self.viewedLinksUseCase = viewedLinksUseCase
        self.resultsProvider = resultsProvider
        self.openLink = openLink
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
    /// - Returns: `true` when all links are deleted
    func clearSelectedLinks() async -> Bool {
        let links = resultsProvider.links(for: selectedIds)
        guard links.isNotEmpty else { return false }

        let clearingAllLinks = links.count == resultsProvider.currentResultIds().count

        do {
            try await viewedLinksUseCase.remove(links)
        } catch {
            MEGALog.log(level: .error, message: "Could not clear selectedLinks. Error: \(error.localizedDescription)")
            return false
        }

        guard clearingAllLinks else {
            exitEditMode()
            return false
        }

        clearedSnackBarMessage = Self.clearSuccessMessage
        return true
    }

    /// Clears the whole history once the store has accepted the change.
    /// - Returns: `true` when the history is successfully cleared
    func clearAllLinks() async -> Bool {
        do {
            try await viewedLinksUseCase.clearHistory()
        } catch {
            MEGALog.log(level: .error, message: "Could not clear history. Error: \(error.localizedDescription)")
            return false
        }

        clearedSnackBarMessage = Self.clearSuccessMessage
        return true
    }

    func exitEditMode() {
        withAnimation {
            editMode = .inactive
        }
    }

    func didSelect(_ selection: SearchResultSelection) {
        guard let link = resultsProvider.link(for: selection.result.id) else {
            MEGALog.log(level: .error, message: "Could not resolve link with handle \(selection.result.id)")
            return
        }
        openLink(link.linkURL)
    }

    func selectionDidChange(_ ids: Set<ResultId>) {
        selectedIds = ids
    }

    // MARK: - Private methods

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

    private func makeSearchBridge() -> SearchBridge {
        let searchBridge = SearchBridge(
            selection: { [weak self] selection in
                self?.didSelect(selection)
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

        searchBridge.viewModeChanged = { [weak self] viewMode in
            self?.viewModeDidChange(viewMode)
        }

        searchBridge.editingChanged = { [weak self] editing in
            self?.editMode = editing ? .active : .inactive
        }

        searchBridge.selectionChanged = { [weak self] ids in
            self?.selectionDidChange(ids)
        }

        return searchBridge
    }

    /// `SearchResultsViewModel.clearSelection()` does not report back through the bridge, and the
    /// sink that would is throttled, so the selection is reset here as well.
    private func listenToEditingChanges() {
        $editMode
            .removeDuplicates()
            .dropFirst()
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
