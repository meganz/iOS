import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentationMock
import MEGASwift
import XCTest

final class CameraUploadStatusBannerViewModelTests: XCTestCase {
    
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
    
    @MainActor
    func testCameraUploadStatusShown_whenStatusEqualsUploadPaused_shouldAutoShowBanner() async throws {
        let sut = makeSUT(
            cameraUploadStats: [
                .init(progress: 1, pendingFilesCount: 1, pendingVideosCount: 0)
            ],
            possiblePauseReason: .noWifi
        )
        
        try await verifyCameraUploadStatus(sut, expectedStatus: .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: 1)), expectedShown: true)
    }
    
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
}

extension CameraUploadStatusBannerViewModelTests {
    private func makeSUT(
        cameraUploadStats: [CameraUploadStatsEntity] = [],
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        possiblePauseReason: CameraUploadPausedReason = .notPaused
    ) -> CameraUploadStatusBannerViewModel {
        CameraUploadStatusBannerViewModel(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: makeCameraUploadSequence(entities: cameraUploadStats),
                possiblePauseReason: possiblePauseReason
            ),
            devicePermissionHandler: devicePermissionHandler
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
        
        XCTAssertEqual(result, expectedShown)
        XCTAssertEqual(sut.cameraUploadBannerStatusViewState, expectedStatus)
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
