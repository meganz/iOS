import Combine
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAPermissions
import MEGAPreference
import SwiftUI

typealias MediaTabInteractiveProvider = MediaTabNavigationBarItemProvider & MediaTabContextMenuProvider & MediaTabContextMenuActionHandler & MediaTabToolbarActionsProvider & MediaTabToolbarActionHandler & MediaTabSharedResourceConsumer

// MARK: - MediaTabViewModel

@MainActor
final class MediaTabViewModel: ObservableObject, @MainActor MediaTabSharedResourceProvider {
    @Published var selectedTab: MediaTab = .timeline {
        didSet {
            guard selectedTab != oldValue else { return }
            updateNavigationBarForCurrentTab()
        }
    }

    @Published var editMode: EditMode = .inactive {
        didSet {
            guard editMode != oldValue else { return }
            showToolbar = editMode == .active
            updateNavigationBarForCurrentTab()
        }
    }

    @Published var navigationTitle: String = "Media" // WIP: Replace with localized string

    @Published var contextMenuConfig: CMConfigEntity?

    @Published private(set) var navigationBarItemViewModels: [NavigationBarItemViewModel] = []
    
    var leadingNavigationBarViewModels: [NavigationBarItemViewModel] {
        navigationBarItemViewModels.filter { $0.placement == .leading }
    }
    
    var trailingNavigationBarViewModels: [NavigationBarItemViewModel] {
        navigationBarItemViewModels.filter { $0.placement == .trailing }
    }

    // MARK: - Toolbar State

    @Published private(set) var showToolbar: Bool = false {
        didSet {
            guard showToolbar != oldValue else { return }
            updateToolbarConfig()
        }
    }

    @Published private(set) var toolbarConfig: MediaBottomToolbarConfig?

    @Published var selectedItemsCount: Int = 0 {
        didSet {
            guard selectedItemsCount != oldValue else { return }
            updateToolbarConfig()
        }
    }

    @Published var hasExportedItems: Bool = false {
        didSet {
            guard hasExportedItems != oldValue else { return }
            updateToolbarConfig()
        }
    }

    @Published var isAllExported: Bool = false {
        didSet {
            guard isAllExported != oldValue else { return }
            updateToolbarConfig()
        }
    }

    let cameraUploadStatusButtonViewModel: CameraUploadStatusButtonViewModel

    var contextMenuManager: ContextMenuManager?
    private var subscriptions = Set<AnyCancellable>()

    let tabViewModels: [MediaTab: any MediaTabInteractiveProvider]

    // MARK: - Initialization

    init(
        tabViewModels: [MediaTab: any MediaTabInteractiveProvider],
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
        devicePermissionHandler: some DevicePermissionsHandling,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default
    ) {
        self.tabViewModels = tabViewModels
        self.cameraUploadStatusButtonViewModel = CameraUploadStatusButtonViewModel(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler,
            preferenceUseCase: preferenceUseCase
        )

        cameraUploadStatusButtonViewModel.onTappedHandler = { [weak self] in
            guard let self else { return }
            self.handleCameraUploadStatusButtonTap()
        }

        configureContextMenuManager()
        subscribeToTabViewModelEvents()
        injectSharedResources()
        updateNavigationBarForCurrentTab()
    }

    // MARK: - Shared Resource Injection

    private func injectSharedResources() {
        for (_, viewModel) in tabViewModels {
            viewModel.sharedResourceProvider = self
        }
    }

    // MARK: - Public Button Action Handlers

    func handleCameraUploadStatusButtonTap() {

    }

    // MARK: - Toolbar Action Handler

    func handleToolbarItemAction(_ action: MediaBottomToolbarAction) {
        // Delegate toolbar action to the current tab's view model
        if let tabViewModel = tabViewModels[selectedTab] {
            tabViewModel.handleToolbarAction(action)
        }
    }

    // MARK: - Private Methods

    private func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(
            displayMenuDelegate: self,
            quickActionsMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo)
        )
    }

    private func subscribeToTabViewModelEvents() {
        // Subscribe to edit mode toggle requests from all tab view models
        for (_, tabViewModel) in tabViewModels {
            tabViewModel.editModeToggleRequested
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.toggleEditMode()
                }
                .store(in: &subscriptions)
        }
    }

    private func toggleEditMode() {
        editMode = editMode == .active ? .inactive : .active
    }

    private func updateNavigationBarForCurrentTab() {
        if let tabViewModel = tabViewModels[selectedTab] {
            contextMenuConfig = tabViewModel.contextMenuConfiguration()
        } else {
            contextMenuConfig = nil
        }

        // Update navigation bar items only if they've changed
        if let itemProvider = tabViewModels[selectedTab] {
            let newItems = itemProvider.navigationBarItems(for: editMode)

            // Only update if items have actually changed (avoid unnecessary redraws)
            if navigationBarItemViewModels != newItems {
                navigationBarItemViewModels = newItems
            }
        }
    }

    // MARK: - Toolbar Configuration

    private func updateToolbarConfig() {
        guard showToolbar else {
            toolbarConfig = nil
            return
        }

        // Get toolbar actions from the current tab's view model
        guard let tabViewModel = tabViewModels[selectedTab],
              let actions = tabViewModel.toolbarActions(
                  selectedItemsCount: selectedItemsCount,
                  hasExportedItems: hasExportedItems,
                  isAllExported: isAllExported
              ),
              !actions.isEmpty else {
            // No actions available, hide toolbar
            toolbarConfig = nil
            return
        }

        toolbarConfig = MediaBottomToolbarConfig(
            actions: actions,
            selectedItemsCount: selectedItemsCount,
            hasExportedItems: hasExportedItems,
            isAllExported: isAllExported
        )
    }
}

// MARK: - DisplayMenuDelegate

extension MediaTabViewModel: DisplayMenuDelegate {
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        if let tabViewModel = tabViewModels[selectedTab] {
            tabViewModel.handleDisplayAction(action)
        }

        if needToRefreshMenu {
            updateNavigationBarForCurrentTab()
        }
    }

    func sortMenu(didSelect sortType: SortOrderType) {
        if let tabViewModel = tabViewModels[selectedTab] {
            tabViewModel.handleSortAction(sortType)
        }

        updateNavigationBarForCurrentTab()
    }
}

// MARK: - QuickActionsMenuDelegate

extension MediaTabViewModel: QuickActionsMenuDelegate {
    func quickActionsMenu(didSelect action: QuickActionEntity, needToRefreshMenu: Bool) {
        if let tabViewModel = tabViewModels[selectedTab] {
            tabViewModel.handleQuickAction(action)
        }

        if needToRefreshMenu {
            updateNavigationBarForCurrentTab()
        }
    }
}
