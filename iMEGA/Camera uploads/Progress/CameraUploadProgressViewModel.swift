import AsyncAlgorithms
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGASwift
import MEGAUIComponent

@MainActor
final class CameraUploadProgressViewModel: ObservableObject {
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
    @Published private(set) var bannerViewModel: BannerViewModel?
    @Published private(set) var uploadStatus = ""
    @Published private(set) var cameraUploadProgressTableViewModel: CameraUploadProgressTableViewModel
    
    @PreferenceWrapper(key: PreferenceKeyEntity.cameraUploadsCellularDataUsageAllowed, defaultValue: false)
    private var isCellularUploadAllowed: Bool
    
    private let monitorCameraUploadUseCase: any MonitorCameraUploadUseCaseProtocol
    private let accountStorageUseCase: any AccountStorageUseCaseProtocol
    private let cameraUploadProgressRouter: any CameraUploadProgressRouting
    
    init(
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol,
        cameraUploadFileDetailsUseCase: some CameraUploadFileDetailsUseCaseProtocol,
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol,
        queuedCameraUploadsUseCase: any QueuedCameraUploadsUseCaseProtocol,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        accountStorageUseCase: some AccountStorageUseCaseProtocol,
        cameraUploadProgressRouter: some CameraUploadProgressRouting
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
        $isCellularUploadAllowed.useCase = preferenceUseCase
    }
    
    func monitorStates() async {
        for await (cameraUploadState, storageState) in combineLatest(monitorCameraUploadUseCase.cameraUploadState, storageState()) {
            let pendingFilesCount = cameraUploadState.stats.pendingFilesCount
            let pausedReason = cameraUploadState.pausedReason
            let format = if pausedReason != nil {
                Strings.localized("cameraUploads.progress.paused.items", comment: "")
            } else {
                Strings.localized("cameraUploads.progress.uploading.items", comment: "")
            }
            uploadStatus = String(format: format, locale: .current, pendingFilesCount)
            
            if storageState == .full {
                showStorageFullBanner()
            } else {
                updateBanner(for: pausedReason)
            }
        }
    }
    
    private func updateBanner(for pausedReason: CameraUploadStateEntity.PausedReason?) {
        guard let pausedReason else {
            bannerViewModel = nil
            return
        }
        
        bannerViewModel = makeBannerViewModel(pausedReason: pausedReason)
    }
    
    private func makeBannerViewModel(
        pausedReason: CameraUploadStateEntity.PausedReason
    ) -> CameraUploadProgressViewModel.BannerViewModel {
        .init(
            title: nil,
            subtitle: pausedReason.bannerSubTitle,
            state: .warning,
            buttonViewModel: makeBannerButtonViewModel(pausedReason: pausedReason))
    }
    
    private func makeBannerButtonViewModel(
        pausedReason: CameraUploadStateEntity.PausedReason
    ) -> CameraUploadProgressViewModel.BannerViewModel.ButtonViewModel? {
        guard !isCellularUploadAllowed,
              case .networkIssue(.noWifi) = pausedReason else { return nil }
        
        return .init(
            text: Strings.Localizable.CameraUploads.Progress.Banner.Paused.AllowMobileData.Button.title,
            action: { [weak self] in self?.isCellularUploadAllowed = true })
    }
    
    private func storageState() -> AnyAsyncSequence<StorageStatusEntity> {
        accountStorageUseCase.onStorageStatusUpdates
            .prepend(accountStorageUseCase.currentStorageStatus)
            .eraseToAnyAsyncSequence()
    }
    
    private func showStorageFullBanner() {
        bannerViewModel = .init(
            title: Strings.Localizable.CameraUploads.Progress.Banner.StorageFull.title,
            subtitle: Strings.Localizable.CameraUploads.Progress.Banner.StorageFull.subtitle,
            state: .error,
            buttonViewModel: .init(
                text: Strings.Localizable.CameraUploads.Progress.Banner.StorageFull.Button.title,
                action: cameraUploadProgressRouter.showUpgradeAccount))
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
