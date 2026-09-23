import Combine
import ContentLibraries
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAPreference
import SwiftUI

@MainActor
final class MediaTimelineTabContentViewModel: ObservableObject, MediaTabContentViewModel, MediaTabSharedResourceConsumer {
    weak var sharedResourceProvider: (any MediaTabSharedResourceProvider)? {
        didSet {
            setupEditModeSubscription()
        }
    }
    let editModeToggleRequested = PassthroughSubject<Void, Never>()
    weak var toolbarCoordinator: (any MediaTabToolbarCoordinatorProtocol)?
   
    let timelineViewModel: NewTimelineViewModel

    private let monitorCameraUploadUseCase: any MonitorCameraUploadUseCaseProtocol
    private let tracker: any AnalyticsTracking
    private let subtitleUpdatePassthroughSubject = CurrentValueSubject<String?, Never>(nil)
    private let updateNavigationBarButtonsPassthroughSubject = PassthroughSubject<Void, Never>()
    private let idleWaitTimeNanoSeconds: UInt64
    private let uploadStateDebounceDuration: Duration
    private var subscriptions = Set<AnyCancellable>()
    
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private(set) var isCameraUploadsEnabled: Bool
    private(set) var delayedUploadUpToDateTask: Task<Void, any Error>? {
        didSet { oldValue?.cancel() }
    }
    private(set) var updatePhotoFilterTask: Task<Void, Never>?
    
    init(
        timelineViewModel: NewTimelineViewModel,
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        idleWaitTimeNanoSeconds: UInt64 = 3 * 1_000_000_000,
        uploadStateDebounceDuration: Duration = .milliseconds(300)
    ) {
        self.timelineViewModel = timelineViewModel
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        self.tracker = tracker
        self.idleWaitTimeNanoSeconds = idleWaitTimeNanoSeconds
        self.uploadStateDebounceDuration = uploadStateDebounceDuration
        $isCameraUploadsEnabled.useCase = preferenceUseCase
        setupEditModeSubscription()
        setupLongPressEditModeBridge()
    }

    func monitorCameraUploads() async {
        guard isCameraUploadsEnabled else {
            subtitleUpdatePassthroughSubject.send(nil)
            return
        }
        
        subtitleUpdatePassthroughSubject.send(Strings.Localizable.CameraUploads.checkingForUploads)
        
        for await state in monitorCameraUploadUseCase.cameraUploadState.debounce(for: uploadStateDebounceDuration) {
            handleCameraUploadState(state: state)
        }
    }
    
    private func handleCameraUploadState(state: CameraUploadStateEntity) {
        let pendingFilesCount = state.stats.pendingFilesCount
        let isPaused = state.pausedReason != nil
        
        let subtitle: String
        if pendingFilesCount == 0 {
            subtitle = Strings.Localizable.CameraUploads.complete
            delayedUploadCompleteSubtitle()
        } else {
            let key = isPaused ? "cameraUploads.progress.paused.items" : "cameraUploads.progress.uploading.items"
            
            subtitle = String(
                format: Strings.localized(key, comment: ""),
                locale: .current,
                pendingFilesCount
            )
        }
        
        subtitleUpdatePassthroughSubject.send(subtitle)
    }
    
    private func delayedUploadCompleteSubtitle() {
        delayedUploadUpToDateTask = Task { [weak self] in
            guard let self else { return }
            try await Task.sleep(nanoseconds: idleWaitTimeNanoSeconds)
            
            subtitleUpdatePassthroughSubject.send(Strings.Localizable.CameraUploads.upToDate)
        }
    }
    
    private func setupEditModeSubscription() {
        guard let sharedResourceProvider else { return }

        sharedResourceProvider.editModePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.timelineViewModel.updateEditMode($0)
            }
            .store(in: &subscriptions)
    }

    private func setupLongPressEditModeBridge() {
        timelineViewModel.photoLibraryContentViewModel.selection.$editMode
            .dropFirst()
            .removeDuplicates(by: { $0.isEditing == $1.isEditing })
            .filter(\.isEditing)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self,
                      sharedResourceProvider?.editMode.isEditing == false else { return }
                editModeToggleRequested.send()
            }
            .store(in: &subscriptions)
    }
}

extension MediaTimelineTabContentViewModel: MediaTabNavigationBarItemProvider {
    var navigationBarUpdatePublisher: AnyPublisher<Void, Never>? {
        let emptyStateChanges = timelineViewModel.photoLibraryContentViewModel.$library
            .map(\.isEmpty)
            .removeDuplicates()
            .dropFirst()
            .map { _ in () }
            .eraseToAnyPublisher()

        return emptyStateChanges
            .merge(with: updateNavigationBarButtonsPassthroughSubject.eraseToAnyPublisher())
            .eraseToAnyPublisher()
    }
    
    func navigationBarItems(for editMode: EditMode) -> [NavigationBarItemViewModel] {
        var items: [NavigationBarItemViewModel] = []
        
        if editMode == .active {
            items.append(MediaNavigationBarItemFactory.cancelButton(
                action: editModeToggleRequested.send))
        } else {
            if let cameraUploadStatusButtonViewModel = sharedResourceProvider?.cameraUploadStatusButtonViewModel {
                items.append(MediaNavigationBarItemFactory.cameraUploadStatusButton(
                    viewModel: cameraUploadStatusButtonViewModel
                ))
            }
            items.append(MediaNavigationBarItemFactory.searchButton { [weak self] in
                self?.sharedResourceProvider?.toggleSearch()
            })
            if let config = sharedResourceProvider?.contextMenuConfig,
               let manager = sharedResourceProvider?.contextMenuManager {
                items.append(MediaNavigationBarItemFactory.contextMenuButton(
                    config: config, manager: manager))
            }
        }
        
        return items
    }
}

// MARK: - MediaTabContextMenuProvider

extension MediaTimelineTabContentViewModel: MediaTabContextMenuProvider {
    func contextMenuConfiguration() -> CMConfigEntity? {
        CMConfigEntity(
            menuType: .menu(type: .mediaTabTimeline),
            sortType: timelineViewModel.sortOrder,
            isCameraUploadExplorer: true,
            isEmptyState: timelineViewModel.photoLibraryContentViewModel.isPhotoLibraryEmpty,
            isCameraUploadsEnabled: timelineViewModel.isCameraUploadsEnabled,
            selectedPhotoFilter: timelineViewModel.photoFilterOptions,
            mediaTimelineSortType: timelineViewModel.mediaTimelineSortType
        )
    }
}

extension MediaTimelineTabContentViewModel: NodeActionDisplayModeProvider {
    var displayMode: DisplayMode {
        .photosTimeline
    }
}

extension MediaTimelineTabContentViewModel: MediaTabContextMenuActionHandler {
    func handleQuickAction(_ action: QuickActionEntity) {
        if action == .settings {
            Task { @MainActor [weak timelineViewModel] in
                // Allow context menu dismissal to complete
                await Task.yield()
                timelineViewModel?.navigateToCameraUploadSettings()
            }
            tracker.trackAnalyticsEvent(with: MediaScreenSettingsMenuToolbarEvent())
        }
    }
    
    func handleSortAction(_ sortType: SortOrderType) {
        if sortType == .newest {
            tracker.trackAnalyticsEvent(with: MediaScreenSortByNewestSelectedEvent())
        } else if sortType == .oldest {
            tracker.trackAnalyticsEvent(with: MediaScreenSortByOldestSelectedEvent())
        }
        
        timelineViewModel.updateSortOrder(sortType.toSortOrderEntity())
    }

    func handleMediaTimelineSortAction(_ sortOrder: MediaTimelineSortOrderEntity) {
        tracker.trackAnalyticsEvent(with: sortOrder.selectedEvent)
        timelineViewModel.updateMediaTimelineSortOrder(sortOrder)
    }
    
    func handlePhotoFilter(option: PhotosFilterOptionsEntity) {
        updatePhotoFilterTask = Task { [weak timelineViewModel, weak updateNavigationBarButtonsPassthroughSubject] in
            await timelineViewModel?.updatePhotoFilter(option: option)
            updateNavigationBarButtonsPassthroughSubject?.send()
        }
    }
}

extension MediaTimelineTabContentViewModel: MediaTabToolbarActionsProvider {
    var toolbarUpdatePublisher: AnyPublisher<Void, Never>? {
        // The same edge as before — the toolbar appearing and going away — counted the way the
        // title counts: a selection of nothing but cells that have not loaded is still a selection.
        timelineViewModel.markedItemCountPublisher
            .map { $0 == 0 }
            .removeDuplicates()
            .dropFirst()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func toolbarConfig() -> MediaBottomToolbarConfig? {
        let actions: [MediaBottomToolbarAction] = [
            .download, .manageLink, .addToAlbum, .moveToRubbishBin, .more]

        return MediaBottomToolbarConfig(
            actions: actions,
            selectedItemsCount: selectedItemsCount
        )
    }

    /// What the user marked, which is not what an action can run on: the toolbar reports marks.
    private var selectedItemsCount: Int {
        timelineViewModel.markedItemCount
    }

    /// The nodes an action runs on. A placeholder's synthetic handle names no file, so the filter
    /// is a last line of defence — `selectPhoto` already refuses them — kept where actions read.
    private var selectedNodesForToolbar: [NodeEntity] {
        timelineViewModel.photoLibraryContentViewModel.selectedPhotos
            .filter { !$0.isTimelinePlaceholder }
    }
}

// MARK: - MediaTabToolbarActionHandler

extension MediaTimelineTabContentViewModel: MediaTabToolbarActionHandler {
    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        let nodes = selectedNodesForToolbar
        // An action runs on what has resolved into a node by the time it is tapped and ignores the
        // rest, so the shortfall is only measurable here: seconds later those marks have resolved
        // and nothing is left to count.
        let ignored = timelineViewModel.pendingSelectionCount
        MEGALogDebug("[MediaTimeline] toolbar \(action) on \(nodes.count) nodes, \(ignored) still loading")
        guard !nodes.isEmpty else { return }

        toolbarCoordinator?.handleToolbarAction(action, with: nodes)
    }
}

extension MediaTimelineTabContentViewModel: MediaTabNavigationSubtitleProvider {
    var subtitleUpdatePublisher: AnyPublisher<String?, Never> {
        subtitleUpdatePassthroughSubject.eraseToAnyPublisher()
    }
}

extension MediaTimelineTabContentViewModel: MediaTabNavigationTitleProvider {
    var titleUpdatePublisher: AnyPublisher<String, Never> {
        let inactiveEditModeTitle = Strings.Localizable.Photos.SearchResults.Media.Section.title
        guard let sharedResourceProvider else {
            return Just(inactiveEditModeTitle).eraseToAnyPublisher()
        }

        let selectionCountPublisher = timelineViewModel.markedItemCountPublisher

        return sharedResourceProvider.selectionTitlePublisher(
            selectionCountPublisher: selectionCountPublisher,
            inactiveEditModeTitle: inactiveEditModeTitle)
    }
}

private extension MediaTimelineSortOrderEntity {
    /// The event for the menu item carrying this order — one per item, reported on every tap, as
    /// the newest / oldest menu has always done. The two modification-time orders keep the
    /// original events: that menu offered no other timestamp, so they have always meant "by last
    /// modified", and renaming them would have cost their stable identifiers.
    var selectedEvent: any EventIdentifier {
        switch self {
        case .newest: MediaScreenSortByNewestSelectedEvent()
        case .oldest: MediaScreenSortByOldestSelectedEvent()
        case .newestByCaptureTime: MediaScreenSortByNewestDateTakenSelectedEvent()
        case .oldestByCaptureTime: MediaScreenSortByOldestDateTakenSelectedEvent()
        }
    }
}
