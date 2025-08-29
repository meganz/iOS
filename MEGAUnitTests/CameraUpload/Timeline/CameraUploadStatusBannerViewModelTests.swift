import Combine
@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPreference
import MEGASwift
import Testing

struct CameraUploadStatusBannerViewModelTests {
    
    @Test
    func cameraUploadDisabled_shouldNotUpdateBannerStatus() async throws {
        let preferenceUseCase = MockPreferenceUseCase(
            dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: false])
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 0.9, pendingFilesCount: 1, pendingVideosCount: 1),
                .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 1)
            ],
            preferenceUseCase: preferenceUseCase)
        
        #expect(sut.cameraUploadBannerStatusViewState == .uploadCompleted)
        
        try await sut.monitorCameraUploadStatus()
        
        #expect(sut.cameraUploadBannerStatusViewState == .uploadCompleted)
    }
    
    @Test
    @MainActor
    func testCameraUploadStatusShown_whenTransitionsToCompleted_shouldAutoShowBanner() async throws {
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 0.9, pendingFilesCount: 1, pendingVideosCount: 0),
                .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0)
            ]
        )
        
        try await verifyCameraUploadStatus(
            sut,
            expectedStatus: .uploadCompleted,
            expectedShown: true
        )
    }
    
    @Test
    @MainActor
    func testCameraUploadStatusShown_whenStatusEqualsPartiallyCompletedDueToVideoUploadsPending_shouldAutoShowBanner() async throws {
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 0.9, pendingFilesCount: 1, pendingVideosCount: 1),
                .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 1)
            ]
        )
        
        try await verifyCameraUploadStatus(
            sut,
            expectedStatus: .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 1)),
            expectedShown: true
        )
    }
    
    @Test
    @MainActor
    func testCameraUploadStatusShown_whenStatusEqualsPartiallyCompletedDueToLimitedAccessToPhotoLibrary_shouldAutoShowBanner() async throws {
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 0.9, pendingFilesCount: 1, pendingVideosCount: 0),
                .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0)
            ],
            devicePermissionHandler: MockDevicePermissionHandler(photoAuthorization: .limited, audioAuthorized: true, videoAuthorized: true)
        )
        
        try await verifyCameraUploadStatus(
            sut,
            expectedStatus: .uploadPartialCompleted(reason: .photoLibraryLimitedAccess),
            expectedShown: true
        )
    }
    
    @Test
    @MainActor
    func testCameraUploadStatusShown_whenStatusEqualsUploadPaused_shouldAutoShowBanner() async throws {
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 1, pendingFilesCount: 1, pendingVideosCount: 0)
            ],
            possiblePauseReason: .noWifi
        )
        
        try await verifyCameraUploadStatus(sut, expectedStatus: .uploadPaused(reason: .noWifiConnection), expectedShown: true)
    }
    
    @Test
    @MainActor
    func testCameraUploadStatusShown_whenStatusEqualsInProgress_shouldReturnFalse() async throws {
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 1, pendingFilesCount: 1, pendingVideosCount: 0)
            ]
        )
        
        try await verifyCameraUploadStatus(
            sut,
            expectedStatus: .uploadInProgress(numberOfFilesPending: 1),
            expectedShown: false
        )
    }
    
    @Test
    @MainActor
    func testCameraUploadStatusShown_whenStartingWithCompletedStatus_shouldNotAutoShowBanner() async throws {
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0)
            ]
        )
        
        try await verifyCameraUploadStatus(
            sut,
            expectedStatus: .uploadCompleted,
            expectedShown: false
        )
    }
    
    @Test
    @MainActor
    func testCameraUploadStatusShown_whenStartingWithPartiallyCompletedStatus_shouldNotAutoShowBanner() async throws {
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 1)
            ]
        )
        
        try await verifyCameraUploadStatus(
            sut,
            expectedStatus: .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 1)),
            expectedShown: false
        )
    }
    
    @Test
    @MainActor
    func testTappedCameraUploadBannerStatus_noWiFiConnectionPausedReason_shouldShowCameraUploadSettings() async throws {
        let router = MockRouter()
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 1, pendingFilesCount: 1, pendingVideosCount: 0)
            ],
            possiblePauseReason: .noWifi,
            cameraUploadsSettingsViewRouter: router
        )
        
        try await verifyCameraUploadStatus(sut, expectedStatus: .uploadPaused(reason: .noWifiConnection), expectedShown: true)
        
        sut.tappedCameraUploadBannerStatus()
        
        #expect(sut.cameraUploadStatusShown == false)
        #expect(router.startCalled == 1)
    }
    
    @Test
    @MainActor
    func testTappedCameraUploadBannerStatus_uploadPartialCompletedLibraryLimitedAccess_shouldShowPhotoPermissionAlert() async throws {
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 0.9, pendingFilesCount: 1, pendingVideosCount: 0),
                .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0)
            ],
            devicePermissionHandler: MockDevicePermissionHandler(photoAuthorization: .limited, audioAuthorized: true, videoAuthorized: true)
        )
        
        try await verifyCameraUploadStatus(
            sut,
            expectedStatus: .uploadPartialCompleted(reason: .photoLibraryLimitedAccess),
            expectedShown: true
        )
        
        sut.tappedCameraUploadBannerStatus()
        
        #expect(sut.cameraUploadStatusShown == false)
        #expect(sut.showPhotoPermissionAlert)
    }
    
    @Test
    func uploadStateStats() async throws {
        let stats =  CameraUploadStatsEntity(progress: 0.3, pendingFilesCount: 3, pendingVideosCount: 0)
        let statesAsyncSequence = SingleItemAsyncSequence(
            item: CameraUploadStateEntity.uploadStats(stats))
            .eraseToAnyAsyncSequence()
        
        let sut = makeSUT(
            cameraUploadState: statesAsyncSequence,
            featureFlagProvider: MockFeatureFlagProvider(list: [.cameraUploadsRevamp: true])
        )
        
        try await verifyCameraUploadStatus(
            sut,
            expectedStatus: .uploadInProgress(numberOfFilesPending: 3),
            expectedShown: false
        )
    }
    
    @Test
    func uploadStatePausedReason() async throws {
        let statesAsyncSequence = SingleItemAsyncSequence(
            item: CameraUploadStateEntity.paused(reason: .lowBattery))
            .eraseToAnyAsyncSequence()
        
        let sut = makeSUT(
            cameraUploadState: statesAsyncSequence,
            featureFlagProvider: MockFeatureFlagProvider(list: [.cameraUploadsRevamp: true])
        )
        
        try await verifyCameraUploadStatus(
            sut,
            expectedStatus: .uploadPaused(reason: .lowBattery),
            expectedShown: true
        )
    }
}

extension CameraUploadStatusBannerViewModelTests {
    private func makeSUT(
        cameraUploadStats: [CameraUploadStatsEntity] = [],
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        possiblePauseReason: CameraUploadPausedReason = .notPaused,
        cameraUploadsSettingsViewRouter: some Routing = MockRouter(),
        cameraUploadState: AnyAsyncSequence<CameraUploadStateEntity> = EmptyAsyncSequence<CameraUploadStateEntity>().eraseToAnyAsyncSequence(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [PreferenceKeyEntity.isCameraUploadsEnabled.rawValue: true]),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> CameraUploadStatusBannerViewModel {
        CameraUploadStatusBannerViewModel(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: makeCameraUploadSequence(entities: cameraUploadStats),
                possiblePauseReason: possiblePauseReason,
                cameraUploadState: cameraUploadState
            ),
            devicePermissionHandler: devicePermissionHandler,
            cameraUploadsSettingsViewRouter: cameraUploadsSettingsViewRouter,
            preferenceUseCase: preferenceUseCase,
            featureFlagProvider: featureFlagProvider
        )
    }
    
    private func makeCameraUploadSequence(entities: [CameraUploadStatsEntity]) -> AnyAsyncSequence<CameraUploadStatsEntity> {
        entities
            .publisher
            .values
            .eraseToAnyAsyncSequence()
    }
    
    @MainActor
    private func verifyCameraUploadStatus(
        _ sut: CameraUploadStatusBannerViewModel,
        expectedStatus: CameraUploadBannerStatusViewStates,
        expectedShown: Bool
    ) async throws {
        try await sut.monitorCameraUploadStatus()
        
        let result = await collectLatestValue(from: sut.$cameraUploadStatusShown)
        
        #expect(result == expectedShown)
        #expect(sut.cameraUploadBannerStatusViewState == expectedStatus)
    }
    
    @MainActor
    private func collectLatestValue<T>(
        from publishedProperty: Published<T>.Publisher
    ) async -> T? {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = publishedProperty
                .first()
                .sink { value in
                    continuation.resume(returning: value)
                    cancellable?.cancel()
                }
        }
    }
}
