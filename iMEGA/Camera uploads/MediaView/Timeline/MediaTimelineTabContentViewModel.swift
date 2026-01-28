import Combine
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
}

extension MediaTimelineTabContentViewModel: MediaTabNavigationBarItemProvider {
    var navigationBarUpdatePublisher: AnyPublisher<Void, Never>? {
        timelineViewModel.photoLibraryContentViewModel.$library
            .map(\.isEmpty)
            .removeDuplicates()
            .dropFirst()
            .map { _ in () }
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
            selectedPhotoFilter: timelineViewModel.photoFilterOptions
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
        }
        
        timelineViewModel.updateSortOrder(sortType.toSortOrderEntity())
    }
    
    func handlePhotoFilter(option: PhotosFilterOptionsEntity) {
        timelineViewModel.updatePhotoFilter(option: option)
        updateNavigationBarButtonsPassthroughSubject.send()
    }
}

extension MediaTimelineTabContentViewModel: MediaTabToolbarActionsProvider {
    var toolbarUpdatePublisher: AnyPublisher<Void, Never>? {
        timelineViewModel.photoLibraryContentViewModel.selection.$photos
            .dropFirst()
            .map { $0.isEmpty }
            .removeDuplicates()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func toolbarConfig() -> MediaBottomToolbarConfig? {
        let selectedNodes = selectedNodesForToolbar
        let selectedCount = selectedNodes.count

        let actions: [MediaBottomToolbarAction] = [
            .download, .manageLink, .addToAlbum, .moveToRubbishBin, .more]

        return MediaBottomToolbarConfig(
            actions: actions,
            selectedItemsCount: selectedCount
        )
    }

    /// Private helper to get selected nodes for internal use
    private var selectedNodesForToolbar: [NodeEntity] {
        Array(timelineViewModel.photoLibraryContentViewModel.selectedPhotos)
    }
}

// MARK: - MediaTabToolbarActionHandler

extension MediaTimelineTabContentViewModel: MediaTabToolbarActionHandler {
    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        let nodes = selectedNodesForToolbar
        guard !nodes.isEmpty else { return }

        toolbarCoordinator?.handleToolbarAction(action, with: nodes)
    }
}

extension MediaTimelineTabContentViewModel: MediaTabNavigationSubtitleProvider {
    var subtitleUpdatePublisher: AnyPublisher<String?, Never> {
        subtitleUpdatePassthroughSubject.eraseToAnyPublisher()
    }
}
