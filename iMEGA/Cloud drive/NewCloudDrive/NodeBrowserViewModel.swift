import Combine
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import Search
import SwiftUI

@MainActor
class NodeBrowserViewModel: ObservableObject {

    // Here, we retain for example context menu delegate handlers, that need to leave as long as this view model.
    // See ContextMenuManager usage inside CloudDriveViewController that uses weakly linked delegates, those objects
    // are retained in the array below to guarantee correct time of life of those objects.
    // Ideally this should not be needed and ContextMenuManager should create menus and retain handlers in there
    // but we are reusing very complex ContextMenuManager that cannot be used in such a way currently.
    var actionHandlers: [Any] = []

    // View is in edit mode once user starts selecting nodes
    // Otherwise, view will be in regular mode, with Bool value indicating whether the back button
    // should be displayed or not
    
    enum ViewState: Equatable {
        enum LeftBarButton: Equatable {
            case back
            case avatar
            case close
        }
        
        case editing
        case regular(leftBarButton: LeftBarButton)
    }

    let searchResultsViewModel: SearchResultsViewModel
    // this is private as view should access only the view when needed, and this depends
    // on the view mode state and the injected instance.
    // Making actual property private removes logic of checking this from the view, allows to cover this by tests with high confidence
    private let mediaDiscoveryViewModel: MediaDiscoveryContentViewModel? // not available for recent buckets yet
    
    // The banner passed during initialization (can be nil).
    // This represents a static warning that does not change state during the display of the current Cloud Drive screen.
    // It is defined once when the view model is created and remains unchanged throughout the lifecycle of this view.
    private let warningViewModel: WarningBannerViewModel?

    // The temporary banner (e.g., storage-related banner).
    // This represents a dynamic warning that may change based on the user's account state,
    // such as storage over-quota events, which can occur before or during the display of the Cloud Drive screen.
    // The view model needs to be able to update this banner's state at all times to reflect real-time changes.
    private var temporaryBannerViewModel: WarningBannerViewModel?
    // Computed property to determine the current banner to display
    var currentBannerViewModel: WarningBannerViewModel? {
        temporaryBannerViewModel ?? warningViewModel
    }
    
    var mediaContentDelegate: MediaContentDelegateHandler?
    private let upgradeEncouragementViewModel: UpgradeEncouragementViewModel?
    private let adsVisibilityViewModel: (any AdsVisibilityViewModelProtocol)?
    
    let config: NodeBrowserConfig
    @Published var contextMenuViewFactory: NodeBrowserContextMenuViewFactory?

    // We can remove sortOrder in the future since we're mainly using sortOrderProvider as the source of truth now. Ticket [SAO-1994]
    private(set) var sortOrder: MEGADomain.SortOrderEntity {
        didSet {
            guard oldValue != sortOrder else { return }
            Task {
                await updateContextMenu()
            }
        }
    }
    @Published var shouldShowMediaDiscoveryAutomatically: Bool?
    @Published var viewMode: ViewModePreferenceEntity
    @Published var editing = false
    @Published var title = ""
    @Published var viewState: ViewState = .regular(leftBarButton: .back)
    @Published var editMode: EditMode = .inactive
    var showAvatarIconInNavBar: Bool {
        viewState == .regular(leftBarButton: .avatar)
    }
    var isSelectionHidden = false
    private var subscriptions = Set<AnyCancellable>()
    let avatarViewModel: MyAvatarViewModel
    let noInternetViewModel: LegacyNoInternetViewModel
    private let storageFullModalAlertViewRouter: any StorageFullModalAlertViewRouting

    @Published var nodeSource: NodeSource
    
    private let nodeSourceUpdatesListener: any CloudDriveNodeSourceUpdatesListening
    private var nodesUpdateListener: any NodesUpdateListenerProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let tracker: any AnalyticsTracking

    private let titleBuilder: (_ isEditing: Bool, _ selectedNodeCount: Int) -> String
    private let onOpenUserProfile: () -> Void
    private let onUpdateSearchBarVisibility: (Bool) -> Void
    private let onBack: () -> Void
    private let onCancel: () -> Void
    private let onEditingChanged: (Bool) -> Void
    private let updateTransferWidgetHandler: () -> Void
    private let sortOrderProvider: () -> MEGADomain.SortOrderEntity
    private let onNodeStructureChanged: () -> Void
    private var nodeSensitivityChangesListenerTask: Task<Void, Never>?
    private var accountStorageMonitoringTask: Task<Void, Never>?
    private var refreshStorageStatusTask: Task<Void, Never>?
    private var updatedViewModesTask: Task<Void, Never>?

    var cloudDriveContextMenuFactory: CloudDriveContextMenuFactory? {
        didSet {
            Task {
                await updateContextMenu()
            }
        }
    }

    init(
        viewMode: ViewModePreferenceEntity,
        searchResultsViewModel: SearchResultsViewModel,
        mediaDiscoveryViewModel: MediaDiscoveryContentViewModel?,
        warningViewModel: WarningBannerViewModel?,
        temporaryWarningViewModel: WarningBannerViewModel?,
        upgradeEncouragementViewModel: UpgradeEncouragementViewModel?,
        adsVisibilityViewModel: (any AdsVisibilityViewModelProtocol)?,
        config: NodeBrowserConfig,
        nodeSource: NodeSource,
        avatarViewModel: MyAvatarViewModel,
        noInternetViewModel: LegacyNoInternetViewModel,
        nodeSourceUpdatesListener: some CloudDriveNodeSourceUpdatesListening,
        nodesUpdateListener: some NodesUpdateListenerProtocol,
        cloudDriveViewModeMonitoringService: some CloudDriveViewModeMonitoring,
        nodeUseCase: some NodeUseCaseProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        // we call this whenever view sate is changed so that:
        // - preference is saved if it's required
        // - context menu can be reconstructed
        viewModeSaver: @escaping (ViewModePreferenceEntity) -> Void,
        storageFullModalAlertViewRouter: some StorageFullModalAlertViewRouting,
        titleBuilder: @escaping (Bool, Int) -> String,
        onOpenUserProfile: @escaping () -> Void,
        onUpdateSearchBarVisibility: @escaping (Bool) -> Void,
        onBack: @escaping () -> Void,
        // triggered in Recents configs by the left nav bar button
        onCancel: @escaping () -> Void,
        onEditingChanged: @escaping (Bool) -> Void,
        updateTransferWidgetHandler: @escaping () -> Void,
        sortOrderProvider: @escaping () -> MEGADomain.SortOrderEntity,
        onNodeStructureChanged: @escaping () -> Void
    ) {
        self.viewMode = viewMode
        self.searchResultsViewModel = searchResultsViewModel
        self.mediaDiscoveryViewModel = mediaDiscoveryViewModel
        self.warningViewModel = warningViewModel
        self.upgradeEncouragementViewModel = upgradeEncouragementViewModel
        self.adsVisibilityViewModel = adsVisibilityViewModel
        self.config = config
        self.nodeSource = nodeSource
        self.sortOrderProvider = sortOrderProvider
        self.sortOrder = sortOrderProvider()
        self.avatarViewModel = avatarViewModel
        self.noInternetViewModel = noInternetViewModel
        self.storageFullModalAlertViewRouter = storageFullModalAlertViewRouter
        self.titleBuilder = titleBuilder
        self.onOpenUserProfile = onOpenUserProfile
        self.onUpdateSearchBarVisibility = onUpdateSearchBarVisibility
        self.onEditingChanged = onEditingChanged
        self.onBack = onBack
        self.onCancel = onCancel
        self.updateTransferWidgetHandler = updateTransferWidgetHandler
        self.nodeSourceUpdatesListener = nodeSourceUpdatesListener
        self.nodesUpdateListener = nodesUpdateListener
        self.nodeUseCase = nodeUseCase
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.accountStorageUseCase = accountStorageUseCase
        self.tracker = tracker
        self.onNodeStructureChanged = onNodeStructureChanged

        $viewMode
            .removeDuplicates()
            .sink { [weak self] viewMode in
                if viewMode == .list {
                    searchResultsViewModel.layout = .list
                }
                if viewMode == .thumbnail {
                    searchResultsViewModel.layout = .thumbnail
                }
                
                // save to preferences/reconstruct context menu
                viewModeSaver(viewMode)
                // hide search bar if we are showing media disovery
                onUpdateSearchBarVisibility(viewMode != .mediaDiscovery)

                Task { await self?.updateContextMenu() }
            }
            .store(in: &subscriptions)
        
        $nodeSource.sink { [weak self] _ in
            // When $nodeSource changes, SwiftUI will update the UI of the view (including the navigation bar items) accordingly,
            // however since we rely on `titleBuilder` to display the title of the navigation bar, we need to refresh the title manually
            self?.refreshTitle()
        }
        .store(in: &subscriptions)
        
        // Some observations regarding editing (selection) state
        // in the legacy CD, so default we should implement it the same way.
        // When editing mode is enabled, there's no way of leaving the screen until edit mode is disabled
        // * user cannot navigate back (there's a select all button where normally back button is)
        // * user cannot navigate forward as selecting cell does mark is as select and does not push/present any new screen
        // * Tab bar is replaced by contextual Toolbar items
        // * More button (···) is replaced by "Cancel" button to exit edit mode
        // * Since user cannot access context More menu, view mode cannot be switched from List/Thumbnail to MediaDiscovery and vice versa.
        // * So those two pieces of state do not have to (and probably shouldn't )be kept sync
        $editing
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] editing in
                guard let self else { return }
                searchResultsViewModel.editing = editing
                mediaDiscoveryViewModel?.editMode = editing ? .active : .inactive
                if !editing {
                    searchResultsViewModel.clearSelection()
                    // need to deselect all here to reset selected items
                    // ticket for this is [FM-1464]
                }

                refreshTitle(isEditing: editing)
                onEditingChanged(editing)
                editMode = editing ? .active : .inactive
            }
            .store(in: &subscriptions)
        
        mediaContentDelegate?.isMediaDiscoverySelectionHandler = {[weak self] isSelectionHidden in
            self?.isSelectionHidden = isSelectionHidden
        }
    
        // we are retaining and then calling the previously assigned closure here
        // as the toolbar handling code need to also be aware of what is selected and need
        // to be called via selectionChanged (See CloudDriveViewControllerFactory)
        let previousClosure = searchResultsViewModel.bridge.selectionChanged
        searchResultsViewModel.bridge.selectionChanged = { [weak self] selected in
            previousClosure(selected)
            guard let self else { return }
            // we not keep the select state in here, keep only one place to store
            // truth state which avoids possibility of incorrect syncing or reading invalid state
            self.refreshTitle()
        }

        searchResultsViewModel.bridge.editingChanged = { [weak self] editing in
            guard let self else { return }
            self.editing = editing
            self.refresh()
        }

        refresh()

        noInternetViewModel.networkConnectionStateChanged = { [weak self] isConnectedToNetwork in
            Task { [weak self] in
                guard isConnectedToNetwork, let self else { return }

                /// wait for 10 attempts to see if the node is loaded in the nodeSource.
                let numberOfTries = 10
                if await waitForNodeToLoad(with: numberOfTries) {
                    refresh()
                }
            }
        }

        addNodesUpdateHandler()
        subscribeToViewModePreferenceChangeNotification(with: cloudDriveViewModeMonitoringService)
        if !accountStorageUseCase.isUnlimitedStorageAccount {
            monitorStorageStatusUpdates()
        }
    }
    
    deinit {
        accountStorageMonitoringTask?.cancel()
        refreshStorageStatusTask?.cancel()
        updatedViewModesTask?.cancel()

        accountStorageMonitoringTask = nil
        refreshStorageStatusTask = nil
        updatedViewModesTask = nil
    }

    var viewModeAwareMediaDiscoveryViewModel: MediaDiscoveryContentViewModel? {
        if viewMode == .mediaDiscovery, let viewModel = mediaDiscoveryViewModel {
            return viewModel
        } 
        return nil
    }
    
    func onLoadTask() async {
        startObservingNodeSourceChanges()
        storageFullModalAlertViewRouter.startIfNeeded()
    }
    
    func onViewAppear() {
        trackScreenViewEvent()
        encourageUpgradeIfNeeded()
        configureAdsVisibility(withDelay: true)
        configureTransferWidgetVisibility()
        updateSortOrderIfNeeded()
        nodeSourceUpdatesListener.startListening()
        listenToNodeSensitivityChanges()
        if !accountStorageUseCase.isUnlimitedStorageAccount {
            refreshStorageBanners()
        }
    }
    
    func onViewDisappear() {
        configureAdsVisibility()
        nodeSourceUpdatesListener.stopListening()
        cancelNodeSensitivityChangesListener()
    }

    func parentNodeMatches(node: NodeEntity) -> Bool {
        node == nodeSource.parentNode
    }

    func updateContextMenu() async {
        guard let cloudDriveContextMenuFactory else { return }
        for await updatedContextMenuViewFactory in cloudDriveContextMenuFactory.makeNodeBrowserContextMenuViewFactory(
            nodeSource: nodeSource,
            viewMode: viewMode,
            isSelectionHidden: isSelectionHidden,
            sortOrder: sortOrder
        ) {
            contextMenuViewFactory = updatedContextMenuViewFactory
        }
    }

    private func trackScreenViewEvent() {
        tracker.trackAnalyticsEvent(with: CloudDriveScreenEvent())
    }
    
    private func startObservingNodeSourceChanges() {
        nodeSourceUpdatesListener.nodeSourcePublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$nodeSource)
    }
    
    private func encourageUpgradeIfNeeded() {
        upgradeEncouragementViewModel?.encourageUpgradeIfNeeded()
    }
    
    /// Configures ad visibility, optionally with a delay.
    ///
    /// A delay is used when called in `onViewAppear` to ensure the view is fully displayed
    /// and the navigation bar animation is complete. Since SwiftUI lacks a direct equivalent
    /// to `viewDidAppear`, this delay helps prevent ads from appearing too soon
    /// and causing unexpected tabbar icon flickering.
    private func configureAdsVisibility(withDelay: Bool = false) {
        Task {
            if withDelay {
                try await Task.sleep(nanoseconds: 500_000_000)
            }
            adsVisibilityViewModel?.configureAdsVisibility()
        }
    }
    
    private func configureTransferWidgetVisibility() {
        updateTransferWidgetHandler()
    }

    private func refresh() {
        refreshViewState()
        refreshTitle()
    }

    private func refreshViewState() {
        let leftBarButton: ViewState.LeftBarButton = {
            if config.displayMode == .recents {
                return .close
            }
            return isBackButtonShown ? .back : .avatar
        }()

        viewState = editing ? .editing : .regular(leftBarButton: leftBarButton)
    }

    private func addNodesUpdateHandler() {
        nodesUpdateListener.onNodesUpdateHandler = { [weak self] updatedNodes in
            guard let self,
                  let parentNode = nodeSource.parentNode else {
                return
            }

            if updatedNodes.contains(
                where: {
                    $0.handle == parentNode.handle &&
                    ($0.changeTypes.contains(.parent)
                     || $0.changeTypes.contains(.removed))
                }
            ) {
                onNodeStructureChanged()
            }
        }
    }

    private func listenToNodeSensitivityChanges() {
        nodeSensitivityChangesListenerTask = Task {
            guard let parentNode = nodeSource.parentNode else { return }

            do {
                for try await _ in sensitiveNodeUseCase.mergeInheritedAndDirectSensitivityChanges(for: parentNode) {
                    if let updatedNode = await nodeUseCase.nodeForHandle(parentNode.handle) {
                        await refreshMenuWithUpdatedNodeSource(.node({ updatedNode }))
                        refresh()
                    }
                }
            } catch {
                MEGALogError("[\(type(of: self))] Error while monitoring inherited node sensitivity. Error: \(error)")
            }
        }
    }

    private func cancelNodeSensitivityChangesListener() {
        nodeSensitivityChangesListenerTask?.cancel()
        nodeSensitivityChangesListenerTask = nil
    }

    private func refreshMenuWithUpdatedNodeSource(_ nodeSource: NodeSource) async {
        self.nodeSource = nodeSource
        await updateContextMenu()
    }

    // this is also triggered from outside when node folder is renamed
    func refreshTitle() {
        refreshTitle(isEditing: editing)
    }
    
    var selectedCount: Int {
        if let mediaDiscoveryViewModel = viewModeAwareMediaDiscoveryViewModel {
            return mediaDiscoveryViewModel.photoLibraryContentViewModel.selection.photos.count
        } else {
            return searchResultsViewModel.selectedResultsCount
        }
    }
    
    private func refreshTitle(isEditing: Bool) {
        title = titleBuilder(isEditing, selectedCount)
    }
    
    private var isBackButtonShown: Bool {
        guard let parentNode = nodeSource.parentNode else { return false }
        return parentNode.nodeType != .root
    }

    func openUserProfile() {
        onOpenUserProfile()
    }
    
    func closeNavBarButtonTapped() {
        onCancel()
    }

    func back() {
        onBack()
    }
    
    func toggleSelection() {
        editing.toggle()
        refresh()
    }
    
    func setEditMode(_ enabled: Bool) {
        guard editing != enabled else { return }
        editing = enabled
        refresh()
    }
    
    func changeViewMode(_ viewMode: ViewModePreferenceEntity) {
        self.viewMode = viewMode
    }

    func changeSortOrder(_ sortOrder: SortOrderType) {
        self.sortOrder = sortOrder.toSortOrderEntity()
        searchResultsViewModel.changeSortOrder(sortOrder.toSearchSortOrderEntity())
    }

    func selectAll() {
        guard case .editing = viewState else { return }
        
        if let mediaDiscoveryViewModel = viewModeAwareMediaDiscoveryViewModel {
            mediaDiscoveryViewModel.toggleAllSelected()
        } else {
            searchResultsViewModel.toggleSelectAll()
        }
        refreshTitle()
    }

    func stopEditing() {
        editing = false
        refresh()
        searchResultsViewModel.bridge.editingCancelled()
        
        CrashlyticsLogger.log(category: .cloudDrive, "stop editing")
    }

    /// Waits for the node to be loaded from the `NodeSource`.
    ///
    /// This method checks if the node is not nil for every interval until the given number of tries.
    ///
    /// - Parameters:
    ///   - numberOfTries: The number of attempts to check if the root node is loaded before this method returns false.
    ///
    /// - Returns: `true` if the root node is loaded, `false` otherwise.
    private func waitForNodeToLoad(with numberOfTries: Int) async -> Bool {
        guard case .node(let parentNodeProvider) = nodeSource, parentNodeProvider() != nil else {
            if numberOfTries == 0 {
                return false
            }

            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return await waitForNodeToLoad(with: numberOfTries - 1)
        }

        return true
    }
    
    private func updateSortOrderIfNeeded() {
        guard case let sortOrder = self.sortOrderProvider(),
              sortOrder != self.sortOrder else {
            return
        }

        changeSortOrder(sortOrder.toSortOrderType())
    }

    private func subscribeToViewModePreferenceChangeNotification(
        with cloudDriveViewModeMonitoringService: some CloudDriveViewModeMonitoring
    ) {
        $nodeSource
            .combineLatest($viewMode)
            .sink { [weak self] (nodeSource, viewMode) in
                self?.updatedViewModesTask?.cancel()
                self?.updatedViewModesTask = Task { @MainActor [weak self] in
                    for await updatedViewMode in cloudDriveViewModeMonitoringService.updatedViewModes(
                        with: nodeSource,
                        currentViewMode: viewMode
                    ) {
                        self?.changeViewMode(updatedViewMode)
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    private func monitorStorageStatusUpdates() {
        guard config.isFromSharedItem != true,
              let displayMode = config.displayMode,
              displayMode == .cloudDrive else { return }
        
        let onStorageStatusUpdateSequence = accountStorageUseCase.onStorageStatusUpdates
        
        accountStorageMonitoringTask = Task { [weak self] in
            for await status in onStorageStatusUpdateSequence {
                MEGALogDebug("[StorageBanner] monitorStorageStatusUpdates - storage status: \(status)")
                self?.updateTemporaryBanner(status: status)
            }
        }
    }
    
    func updateTemporaryBanner(status: StorageStatusEntity) {
        MEGALogDebug("[StorageBanner] updateTemporaryBanner, current warning type: \(String(describing: temporaryBannerViewModel?.warningType)), new storage status: \(status)")
        switch status {
        case .full:
            if temporaryBannerViewModel?.warningType != .fullStorageOverQuota {
                temporaryBannerViewModel = makeSOQBanerViewModel(.fullStorageOverQuota)
            }
        case .almostFull:
            guard accountStorageUseCase.shouldShowStorageBanner else {
                resetTemporaryBanner()
                return
            }
            temporaryBannerViewModel = makeSOQBanerViewModel(
                .almostFullStorageOverQuota,
                shouldShowCloseButton: true,
                closeButtonAction: { [weak self] in
                    self?.resetTemporaryBanner()
                    self?.objectWillChange.send()
                    self?.accountStorageUseCase.updateLastStorageBannerDismissDate()
                }
            )
        default:
            resetTemporaryBanner()
        }
        objectWillChange.send()
    }
    
    func refreshStorageBanners() {
        guard config.isFromSharedItem != true,
              let displayMode = config.displayMode,
              displayMode == .cloudDrive else {
            return
        }
        MEGALogDebug("[StorageBanner] refreshStorageBanners - storage status: \(accountStorageUseCase.currentStorageStatus)")
        if accountStorageUseCase.shouldRefreshStorageStatus {
            refreshStorageStatus()
        }
        updateTemporaryBanner(status: accountStorageUseCase.currentStorageStatus)
    }
    
    /// Refreshes the current storage status asynchronously and updates the temporary storage banner if needed.
    ///
    /// This method initiates a background task to refresh the storage status by calling `refreshCurrentStorageState()`
    /// on the `accountStorageUseCase`. The storage status is cached to avoid repetitive asynchronous calls. The value is
    /// fetched and stored the first time this method is called, and any subsequent updates to the storage status are handled
    /// by receiving `EventType.storage` type events, which keep the cached value updated. If a logout occurs, this cached value is reset.
    private func refreshStorageStatus() {
        refreshStorageStatusTask = Task { [weak self] in
            if let currentStorageStatus = try? await self?.accountStorageUseCase.refreshCurrentStorageState() {
                self?.updateTemporaryBanner(status: currentStorageStatus)
            }
        }
    }
    
    private func resetTemporaryBanner() {
        temporaryBannerViewModel = nil
    }
    
    private func makeSOQBanerViewModel(
        _ warningType: WarningBannerType,
        shouldShowCloseButton: Bool = false,
        closeButtonAction: (() -> Void)? = nil
    ) -> WarningBannerViewModel {
        WarningBannerViewModel(
            warningType: warningType,
            router: WarningBannerViewRouter(),
            shouldShowCloseButton: shouldShowCloseButton,
            closeButtonAction: closeButtonAction
        )
    }
}

extension NodeBrowserViewModel {
    /// Decides whether the observing View needs to show its navigation bar back button or not.
    var hidesBackButton: Bool {
        switch viewState {
        case .editing:
            true
        case .regular(let leftBarButton):
            leftBarButton != .back
        }
    }
}
