import AsyncAlgorithms
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPreference
import MEGASwift
import MEGAUIComponent

@MainActor
final class CameraUploadProgressViewModel: ObservableObject {
    enum ViewState: Equatable {
        case loading
        case loaded
        case completed
    }
    struct BannerViewModel {
        let title: String?
        let subtitle: String
        let state: MEGABannerState
        let buttonViewModel: ButtonViewModel?
        
        struct ButtonViewModel {
            let text: String
            let action: () -> Void
        }
    }
    @Published private(set) var viewState: ViewState = .loading
    @Published private(set) var bannerViewModel: BannerViewModel?
    @Published private(set) var uploadStatus = ""
    @Published private(set) var cameraUploadProgressTableViewModel: CameraUploadProgressTableViewModel
    @Published var showPhotoPermissionAlert = false
    
    @PreferenceWrapper(key: PreferenceKeyEntity.cameraUploadsCellularDataUsageAllowed, defaultValue: false)
    private var isCellularUploadAllowed: Bool
    @PreferenceWrapper(key: PreferenceKeyEntity.isVideoUploadEnabled, defaultValue: false)
    private var isVideoUploadEnabled: Bool
    
    private let monitorCameraUploadUseCase: any MonitorCameraUploadUseCaseProtocol
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private let cameraUploadProgressRouter: any CameraUploadProgressRouting
    private let devicePermissionHandler: any DevicePermissionsHandling
    private let notificationCenter: NotificationCenter
    
    private var monitorVideoSettingsTask: Task<Void, Never>?
    
    init(
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol,
        cameraUploadFileDetailsUseCase: some CameraUploadFileDetailsUseCaseProtocol,
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol,
        queuedCameraUploadsUseCase: any QueuedCameraUploadsUseCaseProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        cameraUploadProgressRouter: some CameraUploadProgressRouting,
        devicePermissionHandler: some DevicePermissionsHandling,
        notificationCenter: NotificationCenter = .default
    ) {
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        cameraUploadProgressTableViewModel = .init(
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            paginationManager: CameraUploadPaginationManager(
                pageSize: 30,
                lookAhead: 4,
                lookBehind: 4,
                queuedCameraUploadsUseCase: queuedCameraUploadsUseCase))
        self.accountStorageUseCase = accountStorageUseCase
        self.cameraUploadProgressRouter = cameraUploadProgressRouter
        self.devicePermissionHandler = devicePermissionHandler
        self.notificationCenter = notificationCenter
        $isCellularUploadAllowed.useCase = preferenceUseCase
        $isVideoUploadEnabled.useCase = preferenceUseCase
        
        monitorVideoSettingChanges()
    }
    
    deinit {
        monitorVideoSettingsTask?.cancel()
    }
    
    func monitorStates() async {
        for await (cameraUploadState, storageState) in combineLatest(monitorCameraUploadUseCase.cameraUploadState, storageState()) {
            let pendingFilesCount = cameraUploadState.stats.pendingFilesCount
            
            updateViewState(pendingFilesCount: pendingFilesCount)
            
            let pausedReason = cameraUploadState.pausedReason
            let format = if pausedReason != nil {
                Strings.localized("cameraUploads.progress.paused.items", comment: "")
            } else {
                Strings.localized("cameraUploads.progress.uploading.items", comment: "")
            }
            uploadStatus = String(format: format, locale: .current, pendingFilesCount)
            
            bannerViewModel = makeBannerViewModel(
                storageState: storageState,
                uploadState: cameraUploadState
            )
        }
    }
      
    func showCameraUploadSettings() {
        cameraUploadProgressRouter.showCameraUploadSettings()
    }
    
    private func makeBannerViewModel(
        storageState: StorageStatusEntity,
        uploadState: CameraUploadStateEntity
    ) -> BannerViewModel? {
        if storageState == .full {
            .storageFullBanner(onUpgrade: cameraUploadProgressRouter.showUpgradeAccount)
        } else if let pausedReason = uploadState.pausedReason {
            .pausedBanner(
                reason: pausedReason,
                isCellularUploadAllowed: isCellularUploadAllowed,
                onAllowCellularData: { [weak self] in self?.isCellularUploadAllowed = true }
            )
        } else if uploadState.stats.pendingFilesCount == 0 && hasLimitedLibraryAccess() {
            .limitedPhotoAccessBanner(
                onUpdatePermissions: { [weak self] in self?.showPhotoPermissionAlert = true })
        } else {
            nil
        }
    }
    
    private func storageState() -> AnyAsyncSequence<StorageStatusEntity> {
        accountStorageUseCase.onStorageStatusUpdates
            .prepend(accountStorageUseCase.currentStorageStatus)
            .eraseToAnyAsyncSequence()
    }
    
    private func hasLimitedLibraryAccess() -> Bool {
        devicePermissionHandler.photoLibraryAuthorizationStatus == .limited
    }
    
    private func updateViewState(pendingFilesCount: UInt) {
        let newState: ViewState = pendingFilesCount == 0 ? .completed : .loaded
        guard newState != viewState else { return }
        viewState = newState
    }
    
    private func monitorVideoSettingChanges() {
        monitorVideoSettingsTask = Task { [weak notificationCenter, weak cameraUploadProgressTableViewModel] in
            guard let notificationCenter,
                  let cameraUploadProgressTableViewModel else { return }
            
            for await _ in notificationCenter.publisher(for: .cameraUploadVideoUploadSettingChanged).values {
                await cameraUploadProgressTableViewModel.reset()
            }
        }
    }
}

extension CameraUploadProgressViewModel.BannerViewModel {
    
    static func pausedBanner(
        reason: CameraUploadStateEntity.PausedReason,
        isCellularUploadAllowed: Bool,
        onAllowCellularData: @escaping () -> Void
    ) -> CameraUploadProgressViewModel.BannerViewModel {
        .init(
            title: nil,
            subtitle: reason.bannerSubTitle,
            state: .warning,
            buttonViewModel: buttonViewModelForPausedReason(
                reason,
                isCellularUploadAllowed: isCellularUploadAllowed,
                onAllowCellularData: onAllowCellularData
            )
        )
    }
    
    static func storageFullBanner(
        onUpgrade: @escaping () -> Void
    ) -> CameraUploadProgressViewModel.BannerViewModel {
        .init(
            title: Strings.Localizable.CameraUploads.Progress.Banner.StorageFull.title,
            subtitle: Strings.Localizable.CameraUploads.Progress.Banner.StorageFull.subtitle,
            state: .error,
            buttonViewModel: .init(
                text: Strings.Localizable.CameraUploads.Progress.Banner.StorageFull.Button.title,
                action: onUpgrade
            )
        )
    }
    
    static func limitedPhotoAccessBanner(
        onUpdatePermissions: @escaping () -> Void
    ) -> CameraUploadProgressViewModel.BannerViewModel {
        .init(
            title: nil,
            subtitle: Strings.Localizable.CameraUploads.Progress.Banner.LimitedAccess.subtitle,
            state: .warning,
            buttonViewModel: .init(
                text: Strings.Localizable.CameraUploads.Progress.Banner.LimitedAccess.Button.title,
                action: onUpdatePermissions
            )
        )
    }
    
    private static func buttonViewModelForPausedReason(
        _ reason: CameraUploadStateEntity.PausedReason,
        isCellularUploadAllowed: Bool,
        onAllowCellularData: @escaping () -> Void
    ) -> ButtonViewModel? {
        guard !isCellularUploadAllowed,
              case .networkIssue(.noWifi) = reason else { return nil }
        
        return .init(
            text: Strings.Localizable.CameraUploads.Progress.Banner.Paused.AllowMobileData.Button.title,
            action: onAllowCellularData
        )
    }
}

private extension CameraUploadStateEntity.PausedReason {
    var bannerSubTitle: String {
        switch self {
        case .lowBattery:
            Strings.Localizable.CameraUploads.Progress.Banner.Paused.LowBattery.subtitle
        case .highThermalState:
            Strings.Localizable.CameraUploads.Progress.Banner.Paused.HighThermalState.subtitle
        case .networkIssue:
            Strings.Localizable.CameraUploads.Progress.Banner.Paused.NetworkIssue.subtitle
        }
    }
}
