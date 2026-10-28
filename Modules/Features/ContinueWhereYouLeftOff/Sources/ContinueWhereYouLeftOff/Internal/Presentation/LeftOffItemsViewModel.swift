import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAFoundation
import MEGAL10n
import MEGASwift
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI

@MainActor
final class LeftOffItemsViewModel: ObservableObject {
    @Published var editMode: EditMode = .inactive
    @Published var isPresentingClearSelectedConfirmation = false
    @Published var isPresentingClearAllConfirmation = false
    @Published private(set) var selectedIds: Set<ResultId> = []

    var clearSelectedItemsTitle: String {
        selectedIds.count == 1
            ? Strings.Localizable.ContinueWhereYouLeftOff.ClearFile.Confirmation.title
            : Strings.Localizable.ContinueWhereYouLeftOff.ClearFiles.Confirmation.title
    }

    var selectionTitle: String {
        guard selectedIds.isNotEmpty else { return Strings.Localizable.selectTitle }
        return Strings.Localizable.General.Format.itemsSelected(selectedIds.count)
    }

    var navigationTitle: String {
        editMode.isEditing ? selectionTitle : Strings.Localizable.Home.Customization.Widget.continueWhereYouLeftOff
    }

    lazy var searchResultsContainerViewModel: SearchResultsContainerViewModel = {
        let searchBridge = makeSearchBridge()
        let searchConfig = SearchConfig.leftOffItems

        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: resultsProvider,
            bridge: searchBridge,
            config: searchConfig,
            layout: .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .unknown,
            listHeaderViewModel: nil,
            isSelectionEnabled: true,
            contentUnavailableViewModelProvider: LeftOffItemsContentUnavailableProvider()
        )

        return SearchResultsContainerViewModel(
            bridge: searchBridge,
            config: searchConfig,
            searchResultsViewModel: searchResultsViewModel,
            sortHeaderConfig: .leftOffItems,
            headerType: .dynamic,
            initialViewMode: viewMode,
            shouldShowMediaDiscoveryModeHandler: { false },
            sortHeaderViewPressedEvent: { }
        )
    }()

    private static let defaultSortOrder = MEGAUIComponent.SortOrder(key: .dateAdded, direction: .descending)

    private let leftOffItemsUseCase: any LeftOffItemsUseCaseProtocol
    private let resultsProvider: any LeftOffItemsResultsProviding
    private let openNode: @MainActor (HandleEntity) -> Void
    private let tracker: any AnalyticsTracking

    private var sortOrder = defaultSortOrder
    private var viewMode: SearchResultsViewMode = .list
    private var subscriptions: Set<AnyCancellable> = []

    convenience init(
        leftOffItemsUseCase: some LeftOffItemsUseCaseProtocol,
        thumbnailUseCase: some ThumbnailUseCaseProtocol,
        openNode: @escaping @MainActor (HandleEntity) -> Void,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.init(
            leftOffItemsUseCase: leftOffItemsUseCase,
            resultsProvider: LeftOffItemsSearchResultsProvider(
                leftOffItemsUseCase: leftOffItemsUseCase,
                mapper: LeftOffItemSearchResultMapper(thumbnailUseCase: thumbnailUseCase)
            ),
            openNode: openNode,
            tracker: tracker
        )
    }

    init(
        leftOffItemsUseCase: some LeftOffItemsUseCaseProtocol,
        resultsProvider: some LeftOffItemsResultsProviding,
        openNode: @escaping @MainActor (HandleEntity) -> Void,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.leftOffItemsUseCase = leftOffItemsUseCase
        self.resultsProvider = resultsProvider
        self.openNode = openNode
        self.tracker = tracker
        listenToEditingChanges()
    }

    func onAppear() {
        tracker.trackAnalyticsEvent(with: ContinueWhereLeftOffScreenEvent())
    }

    func requestClearSelectedItems() {
        guard selectedIds.isNotEmpty else { return }
        isPresentingClearSelectedConfirmation = true
    }

    func requestClearAllItems() {
        tracker.trackAnalyticsEvent(with: ContinueWhereLeftOffClearHistoryMenuItemEvent())
        isPresentingClearAllConfirmation = true
    }

    func clearSelectedItems() async {
        let items = resultsProvider.items(for: selectedIds)
        guard items.isNotEmpty else { return }

        do {
            try await leftOffItemsUseCase.remove(items)
        } catch {
            MEGALog.log(level: .error, message: "Could not clear selected left off items. Error: \(error.localizedDescription)")
            return
        }

        exitEditMode()
    }

    func clearAllItems() async -> Bool {
        tracker.trackAnalyticsEvent(with: ContinueWhereLeftOffClearHistoryDialogConfirmedEvent())
        do {
            try await leftOffItemsUseCase.clearHistory()
        } catch {
            MEGALog.log(level: .error, message: "Could not clear left off history. Error: \(error.localizedDescription)")
            return false
        }

        return true
    }

    func exitEditMode() {
        withAnimation {
            editMode = .inactive
        }
    }

    func didSelect(_ selection: SearchResultSelection) {
        tracker.trackAnalyticsEvent(with: ContinueWhereLeftOffListItemPressedEvent())
        openNode(selection.result.id)
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
            tracker.trackAnalyticsEvent(with: ContinueWhereLeftOffGridViewSelectedEvent())
            searchResultsContainerViewModel.update(pageLayout: .thumbnail)
        case .list:
            tracker.trackAnalyticsEvent(with: ContinueWhereLeftOffListViewSelectedEvent())
            searchResultsContainerViewModel.update(pageLayout: .list)
        case .mediaDiscovery:
            break
        }
    }

    private func sortOrderDidChange(_ sortOrder: MEGAUIComponent.SortOrder) {
        self.sortOrder = sortOrder
        guard let event = sortOrder.analyticsEvent else { return }
        tracker.trackAnalyticsEvent(with: event)
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
                self?.sortOrderDidChange(sortOrder)
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

private extension MEGAUIComponent.SortOrder {
    var analyticsEvent: (any EventIdentifier)? {
        switch (key, direction) {
        case (.name, .ascending): ContinueWhereLeftOffSortByNameAscendingSelectedEvent()
        case (.name, .descending): ContinueWhereLeftOffSortByNameDescendingSelectedEvent()
        case (.dateAdded, .descending): ContinueWhereLeftOffSortByDateNewestSelectedEvent()
        case (.dateAdded, .ascending): ContinueWhereLeftOffSortByDateOldestSelectedEvent()
        default: nil
        }
    }
}
