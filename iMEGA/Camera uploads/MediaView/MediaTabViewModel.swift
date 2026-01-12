import Combine
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPhotos
import MEGAPreference
import SwiftUI

@MainActor
final class MediaTabViewModel: ObservableObject, MediaTabSharedResourceProvider {
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

    @Published var navigationTitle: String = Strings.Localizable.Photos.SearchResults.Media.Section.title
    @Published var navigationSubtitle: String?

    @Published var contextMenuConfig: CMConfigEntity?
    
    @Published var isSearching = false

    @Published private(set) var navigationBarItemViewModels: [NavigationBarItemViewModel] = []
    
    var leadingNavigationBarViewModels: [NavigationBarItemViewModel] {
        navigationBarItemViewModels.filter { $0.placement == .leading }
    }
    
    var trailingNavigationBarViewModels: [NavigationBarItemViewModel] {
        navigationBarItemViewModels.filter { $0.placement == .trailing }
    }
    
    var nodeActionDisplayMode: DisplayMode {
        guard let tabViewModel = tabViewModels[selectedTab] as? any NodeActionDisplayModeProvider else {
            return .cloudDrive
        }
        return tabViewModel.displayMode
    }

    // MARK: - Toolbar State

    @Published private(set) var showToolbar: Bool = false {
        didSet {
            guard showToolbar != oldValue else { return }
            updateToolbarConfig()
        }
    }

    @Published private(set) var toolbarConfig: MediaBottomToolbarConfig?

    let cameraUploadStatusButtonViewModel: CameraUploadStatusButtonViewModel
    let visualMediaSearchResultsViewModel: VisualMediaSearchResultsViewModel

    var contextMenuManager: ContextMenuManager?
    var editModePublisher: Published<EditMode>.Publisher { $editMode }
    private var subscriptions = Set<AnyCancellable>()

    let tabViewModels: [MediaTab: any MediaTabContentViewModel]

    // MARK: - Initialization

    init(
        tabViewModels: [MediaTab: any MediaTabContentViewModel],
        visualMediaSearchResultsViewModel: VisualMediaSearchResultsViewModel,
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
        devicePermissionHandler: some DevicePermissionsHandling,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        cameraUploadsSettingsViewRouter: some Routing,
        cameraUploadProgressRouter: some CameraUploadProgressRouting
    ) {
        self.tabViewModels = tabViewModels
        self.visualMediaSearchResultsViewModel = visualMediaSearchResultsViewModel
        self.cameraUploadStatusButtonViewModel = CameraUploadStatusButtonViewModel(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler,
            preferenceUseCase: preferenceUseCase,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            cameraUploadProgressRouter: cameraUploadProgressRouter
        )

        configureContextMenuManager()
        subscribeToTabViewModelEvents()
        injectSharedResources()
        updateNavigationBarForCurrentTab()
    }

    // MARK: - Shared Resource Injection

    private func injectSharedResources() {
        tabViewModels.values
            .compactMap { $0 as? any MediaTabSharedResourceConsumer }
            .forEach { $0.sharedResourceProvider = self }
    }

    // MARK: - Toolbar Action Handler

    func handleToolbarItemAction(_ action: MediaBottomToolbarAction) {
        guard let tabViewModel = tabViewModels[selectedTab] as? any MediaTabToolbarActionHandler else { return }
        tabViewModel.handleToolbarAction(action)
    }

    // MARK: - Private Methods

    private func configureContextMenuManager() {
        contextMenuManager = ContextMenuManager(
            displayMenuDelegate: self,
            quickActionsMenuDelegate: self,
            createContextMenuUseCase: CreateContextMenuUseCase(repo: CreateContextMenuRepository.newRepo),
            videoFilterMenuDelegate: self,
            photoFilterOptionDelegate: self
        )
    }

    private func subscribeToTabViewModelEvents() {
        // Subscribe to edit mode toggle requests from all tab view models
        tabViewModels.values
            .compactMap { $0 as? any MediaTabContextMenuActionHandler }
            .forEach { tabViewModel in
                tabViewModel.editModeToggleRequested
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in
                        self?.toggleEditMode()
                    }
                    .store(in: &subscriptions)
            }
        
        // Respond to navigation bar update requests from current tab
        $selectedTab
            .compactMap { [weak self] selectedTab in
                (self?.tabViewModels[selectedTab] as? any MediaTabNavigationBarItemProvider)?.navigationBarUpdatePublisher
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateNavigationBarForCurrentTab()
            }
            .store(in: &subscriptions)

        // Subscribe to toolbar update requests from current tab
        $selectedTab
            .compactMap { [weak self] selectedTab in
                (self?.tabViewModels[selectedTab] as? any MediaTabToolbarActionsProvider)?.toolbarUpdatePublisher
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateToolbarConfig()
            }
            .store(in: &subscriptions)

        // Subscribe to title updates from selected tab
        $selectedTab
            .compactMap { [weak self] selectedTab in
                (self?.tabViewModels[selectedTab] as? any MediaTabNavigationTitleProvider)?.titleUpdatePublisher
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleTitleUpdate(update)
            }
            .store(in: &subscriptions)
        
        $selectedTab.combineLatest($editMode)
            .map { [weak self] selectedTab, editMode in
                guard !editMode.isEditing else { return Just<String?>(nil).eraseToAnyPublisher() }
                return (self?.tabViewModels[selectedTab] as? any MediaTabNavigationSubtitleProvider)?.subtitleUpdatePublisher ?? Just(nil).eraseToAnyPublisher()
            }
            .switchToLatest()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$navigationSubtitle)
    }

    private func toggleEditMode() {
        editMode = editMode == .active ? .inactive : .active
    }

    private func updateNavigationBarForCurrentTab() {
        guard let tabViewModel = tabViewModels[selectedTab] else {
            contextMenuConfig = nil
            return
        }
        contextMenuConfig = (tabViewModel as? any MediaTabContextMenuProvider)?.contextMenuConfiguration()
        
        // Update navigation bar items only if they've changed
        let newItems = (tabViewModel as? any MediaTabNavigationBarItemProvider)?.navigationBarItems(for: editMode) ?? []
        if navigationBarItemViewModels != newItems {
            navigationBarItemViewModels = newItems
        }
    }

    // MARK: - Toolbar Configuration

    private func updateToolbarConfig() {
        guard showToolbar else {
            toolbarConfig = nil
            return
        }

        // Get toolbar configuration from the current tab's view model
        guard let tabViewModel = tabViewModels[selectedTab] as? (any MediaTabToolbarActionsProvider) else {
            toolbarConfig = nil
            return
        }

        toolbarConfig = tabViewModel.toolbarConfig()
    }
    
    private func handleTitleUpdate(_ newTitle: String) {
        guard newTitle != navigationTitle else { return }
        navigationTitle = newTitle
    }
}

// MARK: - DisplayMenuDelegate

extension MediaTabViewModel: DisplayMenuDelegate {
    func displayMenu(didSelect action: DisplayActionEntity, needToRefreshMenu: Bool) {
        if let tabViewModel = tabViewModels[selectedTab] as? (any MediaTabContextMenuActionHandler) {
            tabViewModel.handleDisplayAction(action)
        }

        if needToRefreshMenu {
            updateNavigationBarForCurrentTab()
        }
    }

    func sortMenu(didSelect sortType: SortOrderType) {
        if let tabViewModel = tabViewModels[selectedTab] as? (any MediaTabContextMenuActionHandler) {
            tabViewModel.handleSortAction(sortType)
        }

        updateNavigationBarForCurrentTab()
    }
}

// MARK: - VideoFilterMenuDelegate

extension MediaTabViewModel: VideoFilterMenuDelegate {
    func videoLocationFilterMenu(didSelect filter: VideoLocationFilterEntity) {
        if let tabViewModel = tabViewModels[selectedTab] as? (any MediaTabContextMenuActionHandler) {
            tabViewModel.handleVideoLocationFilter(filter)
        }

        updateNavigationBarForCurrentTab()
    }

    func videoDurationFilterMenu(didSelect filter: VideoDurationFilterEntity) {
        if let tabViewModel = tabViewModels[selectedTab] as? (any MediaTabContextMenuActionHandler) {
            tabViewModel.handleVideoDurationFilter(filter)
        }

        updateNavigationBarForCurrentTab()
    }
}

// MARK: - QuickActionsMenuDelegate

extension MediaTabViewModel: QuickActionsMenuDelegate {
    func quickActionsMenu(didSelect action: QuickActionEntity, needToRefreshMenu: Bool) {
        if let tabViewModel = tabViewModels[selectedTab] as? (any MediaTabContextMenuActionHandler) {
            tabViewModel.handleQuickAction(action)
        }

        if needToRefreshMenu {
            updateNavigationBarForCurrentTab()
        }
    }
}

// MARK: - PhotoFilterOptionDelegate

extension MediaTabViewModel: PhotoFilterOptionDelegate {
    func photoFilter(option: PhotosFilterOptionsEntity) {
        if let tabViewModel = tabViewModels[selectedTab] as? (any MediaTabContextMenuActionHandler) {
            tabViewModel.handlePhotoFilter(option: option)
        }

        updateNavigationBarForCurrentTab()
    }
}

extension MediaTabViewModel {
    var searchText: Binding<String> {
        Binding { [weak self] in
            self?.visualMediaSearchResultsViewModel.searchText ?? ""
        } set: { [weak self] in
            self?.visualMediaSearchResultsViewModel.searchText = $0
        }
    }
    
    func toggleSearch() {
        isSearching.toggle()
    }
}
