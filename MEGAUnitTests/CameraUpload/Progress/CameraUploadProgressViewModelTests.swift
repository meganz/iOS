@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPreference
import MEGAPreferenceMocks
import MEGASwift
import MEGAUIComponent
import Testing

struct CameraUploadProgressViewModelTests {

    @MainActor
    @Suite("Monitor States")
    struct MonitorStates {
        let uploadStats = CameraUploadStatsEntity(progress: 50, pendingFilesCount: 10, pendingVideosCount: 2)
        
        @Test(arguments: [
            Optional<CameraUploadStateEntity.PausedReason>.none,
            .some(.lowBattery)
        ])
        func uploadStatus(pausedReason: CameraUploadStateEntity.PausedReason?) async {
            let item = CameraUploadStateEntity(
                stats: uploadStats,
                pausedReason: pausedReason)
            let cameraUploadStateAsyncSequence = SingleItemAsyncSequence(
                item: item)
                .eraseToAnyAsyncSequence()
            let monitorCameraUploadUseCase = MockMonitorCameraUploadUseCase(
                cameraUploadState: cameraUploadStateAsyncSequence
            )
            let accountStorageUseCase = MockAccountStorageUseCase(
                currentStorageStatus: .noStorageProblems)
            let sut = makeSUT(
                monitorCameraUploadUseCase: monitorCameraUploadUseCase,
                accountStorageUseCase: accountStorageUseCase)
            
            #expect(sut.viewState == .loading)
            
            await performAsyncTestOnMonitorStates(sut: sut, publisher: sut.$uploadStatus) {
                #expect($0 == CameraUploadProgressViewModelTests.uploadStatus(
                    pendingFilesCount: uploadStats.pendingFilesCount,
                    isPaused: pausedReason != nil))
                #expect(sut.viewState == .loaded)
            }
        }
        
        @Test(arguments: [
            (CameraUploadStateEntity.PausedReason.lowBattery, Strings.Localizable.CameraUploads.Progress.Banner.Paused.LowBattery.subtitle),
            (.highThermalState, Strings.Localizable.CameraUploads.Progress.Banner.Paused.HighThermalState.subtitle),
            (.networkIssue(.noConnection), Strings.Localizable.CameraUploads.Progress.Banner.Paused.NetworkIssue.subtitle),
            (.networkIssue(.noWifi), Strings.Localizable.CameraUploads.Progress.Banner.Paused.NetworkIssue.subtitle)
        ])
        func pausedBannerIsCorrect(
            pausedReason: CameraUploadStateEntity.PausedReason,
            expectedSubtitle: String
        ) async {
            let item = CameraUploadStateEntity(
                stats: uploadStats,
                pausedReason: pausedReason)
            let cameraUploadStateAsyncSequence = SingleItemAsyncSequence(
                item: item)
                .eraseToAnyAsyncSequence()
            let monitorCameraUploadUseCase = MockMonitorCameraUploadUseCase(
                cameraUploadState: cameraUploadStateAsyncSequence
            )
            let accountStorageUseCase = MockAccountStorageUseCase(
                currentStorageStatus: .noStorageProblems)
            let sut = makeSUT(
                monitorCameraUploadUseCase: monitorCameraUploadUseCase,
                preferenceUseCase: MockPreferenceUseCase(dict: [PreferenceKeyEntity.cameraUploadsCellularDataUsageAllowed.rawValue: true]),
                accountStorageUseCase: accountStorageUseCase)
            
            await performAsyncTestOnMonitorStates(sut: sut, publisher: sut.$bannerViewModel) {
                expectBannerViewModel(
                    $0,
                    subtitle: expectedSubtitle,
                    state: .warning,
                )
            }
        }
        
        @Test
        func allowMobileDataBannerUpdateSettings() async {
            let item = CameraUploadStateEntity(
                stats: uploadStats,
                pausedReason: .networkIssue(.noWifi))
            let cameraUploadStateAsyncSequence = SingleItemAsyncSequence(
                item: item)
                .eraseToAnyAsyncSequence()
            let monitorCameraUploadUseCase = MockMonitorCameraUploadUseCase(
                cameraUploadState: cameraUploadStateAsyncSequence
            )
            let cameraUploadsCellularDataUsageAllowedKey = PreferenceKeyEntity.cameraUploadsCellularDataUsageAllowed.rawValue
            let accountStorageUseCase = MockAccountStorageUseCase(
                currentStorageStatus: .noStorageProblems)
            let preferenceUseCase = MockPreferenceUseCase(dict: [cameraUploadsCellularDataUsageAllowedKey: false])
            let sut = makeSUT(
                monitorCameraUploadUseCase: monitorCameraUploadUseCase,
                preferenceUseCase: preferenceUseCase,
                accountStorageUseCase: accountStorageUseCase)
            
            await performAsyncTestOnMonitorStates(sut: sut, publisher: sut.$bannerViewModel) {
                #expect($0?.buttonViewModel?.text == Strings.Localizable.CameraUploads.Progress.Banner.Paused.AllowMobileData.Button.title)
                $0?.buttonViewModel?.action()
                #expect(preferenceUseCase.dict[cameraUploadsCellularDataUsageAllowedKey] as? Bool == true)
            }
        }
        
        @Test
        func storageFullBanner() async {
            let item = CameraUploadStateEntity(
                stats: uploadStats,
                pausedReason: .networkIssue(.noWifi))
            let cameraUploadStateAsyncSequence = SingleItemAsyncSequence(
                item: item)
                .eraseToAnyAsyncSequence()
            let monitorCameraUploadUseCase = MockMonitorCameraUploadUseCase(
                cameraUploadState: cameraUploadStateAsyncSequence
            )
            let accountStorageUseCase = MockAccountStorageUseCase(
                currentStorageStatus: .full)
           let cameraUploadProgressRouter = MockCameraUploadProgressRouter()
            let sut = makeSUT(
                monitorCameraUploadUseCase: monitorCameraUploadUseCase,
                accountStorageUseCase: accountStorageUseCase,
                cameraUploadProgressRouter: cameraUploadProgressRouter)
            
            await performAsyncTestOnMonitorStates(sut: sut, publisher: sut.$bannerViewModel) { bannerViewModel in
                expectBannerViewModel(
                    bannerViewModel,
                    title: Strings.Localizable.CameraUploads.Progress.Banner.StorageFull.title,
                    subtitle: Strings.Localizable.CameraUploads.Progress.Banner.StorageFull.subtitle,
                    state: .error,
                    buttonText: Strings.Localizable.CameraUploads.Progress.Banner.StorageFull.Button.title
                )
                bannerViewModel?.buttonViewModel?.action()
                #expect(cameraUploadProgressRouter.showUpgradeAccountCalledCount == 1)
            }
        }
        
        @Test
        func uploadCompleteLimitedAccessBanner() async {
            let item = CameraUploadStateEntity(
                stats: .init(progress: 100, pendingFilesCount: 0, pendingVideosCount: 0))
            let cameraUploadStateAsyncSequence = SingleItemAsyncSequence(
                item: item)
                .eraseToAnyAsyncSequence()
            let monitorCameraUploadUseCase = MockMonitorCameraUploadUseCase(
                cameraUploadState: cameraUploadStateAsyncSequence
            )
            let devicePermissionHandler = MockDevicePermissionHandler(
                photoAuthorization: .limited
            )
            
            let sut = makeSUT(
                monitorCameraUploadUseCase: monitorCameraUploadUseCase,
                devicePermissionHandler: devicePermissionHandler)
            
            await performAsyncTestOnMonitorStates(sut: sut, publisher: sut.$bannerViewModel) { bannerViewModel in
                expectBannerViewModel(
                    bannerViewModel,
                    title: nil,
                    subtitle: Strings.Localizable.CameraUploads.Progress.Banner.LimitedAccess.subtitle,
                    state: .warning,
                    buttonText: Strings.Localizable.CameraUploads.Progress.Banner.LimitedAccess.Button.title
                )
                bannerViewModel?.buttonViewModel?.action()
                #expect(sut.showPhotoPermissionAlert)
                #expect(sut.viewState == .completed)
            }
        }
        
        private func performAsyncTestOnMonitorStates<T>(
            sut: CameraUploadProgressViewModel,
            publisher: Published<T>.Publisher,
            expectation: @escaping (T) -> Void
        ) async {
            var monitorTask: Task<Void, Never>?
            await confirmation { confirmation in
                let subscription = publisher
                    .dropFirst()
                    .sink { value in
                        expectation(value)
                        confirmation()
                    }
                
                monitorTask = Task {
                    await sut.monitorStates()
                }
                await monitorTask?.value
                subscription.cancel()
            }
            monitorTask?.cancel()
        }
        
        private func expectBannerViewModel(
            _ banner: CameraUploadProgressViewModel.BannerViewModel?,
            title: String? = nil,
            subtitle: String? = nil,
            state: MEGABannerState,
            buttonText: String? = nil
        ) {
            #expect(banner?.title == title)
            #expect(banner?.subtitle == subtitle)
            #expect(banner?.state == state)
            #expect(banner?.buttonViewModel?.text == buttonText)
        }
    }
    
    @MainActor
    @Test
    func onAppear() {
        let tracker = MockTracker()
        let sut = Self.makeSUT(
            tracker: tracker)
        
        sut.onAppear()
        
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [CameraUploadProgressScreenEvent()]
        )
    }
    
    @MainActor
    @Test
    func showCameraUploadSettings() async throws {
        let cameraUploadProgressRouter = MockCameraUploadProgressRouter()
        let tracker = MockTracker()
        let sut = Self.makeSUT(
            cameraUploadProgressRouter: cameraUploadProgressRouter,
            tracker: tracker)
        
        sut.showCameraUploadSettings()
        
        #expect(cameraUploadProgressRouter.showCameraUploadSettingsCalledCount == 1)
        Test.assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [CameraUploadsSettingsMenuItemEvent()]
        )
    }

    @MainActor
    private static func makeSUT(
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase(),
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol = MockCameraUploadProgressUseCase(),
        cameraUploadFileDetailsUseCase: some CameraUploadFileDetailsUseCaseProtocol = MockCameraUploadFileDetailsUseCase(),
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol = MockPhotoLibraryThumbnailUseCase(),
        queuedCameraUploadsUseCase: any QueuedCameraUploadsUseCaseProtocol = MockQueuedCameraUploadsUseCase(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        accountStorageUseCase: some AccountStorageUseCaseProtocol = MockAccountStorageUseCase(),
        cameraUploadProgressRouter: some CameraUploadProgressRouting = MockCameraUploadProgressRouter(),
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        tracker: some AnalyticsTracking = MockTracker(),
        notificationCenter: NotificationCenter = .default
    ) -> CameraUploadProgressViewModel {
        .init(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            queuedCameraUploadsUseCase: queuedCameraUploadsUseCase,
            preferenceUseCase: preferenceUseCase,
            accountStorageUseCase: accountStorageUseCase,
            cameraUploadProgressRouter: cameraUploadProgressRouter,
            devicePermissionHandler: devicePermissionHandler,
            tracker: tracker,
            notificationCenter: notificationCenter)
    }
    
    private static func uploadStatus(pendingFilesCount: UInt, isPaused: Bool = false) -> String {
        let format = if isPaused {
            Strings.localized("cameraUploads.progress.paused.items", comment: "")
        } else {
            Strings.localized("cameraUploads.progress.uploading.items", comment: "")
        }
        return String(format: format, locale: .current, pendingFilesCount)
    }
}
