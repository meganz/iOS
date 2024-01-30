@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentationMock
import MEGASwift
import XCTest

final class CameraUploadStatusBannerViewModelTests: XCTestCase {
    
    func testCameraUploadStatusShown_whenTransitionsToCompleted_shouldAutoShowBanner() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: makeCameraUploadSequence(entities: [
                    .init(progress: 0.9, pendingFilesCount: 1, pendingVideosCount: 0),
                    .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0)
                ]))
        )
                
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
             .values
             .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, true)
        XCTAssertEqual(sut.cameraUploadBannerStatusViewState, .uploadCompleted)
    }
    
    func testCameraUploadStatusShown_whenStatusEqualsPartiallyCompletedDueToVideoUploadsPending_shouldAutoShowBanner() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: makeCameraUploadSequence(entities: [
                    .init(progress: 0.9, pendingFilesCount: 1, pendingVideosCount: 1),
                    .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 1)
                ]))
        )
                
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
             .values
             .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, true)
        XCTAssertEqual(sut.cameraUploadBannerStatusViewState, .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 1)))
    }
    
    func testCameraUploadStatusShown_whenStatusEqualsPartiallyCompletedDueToLimitedAccessToPhotoLibrary_shouldAutoShowBanner() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: makeCameraUploadSequence(
                    entities: [
                        .init(progress: 0.9, pendingFilesCount: 1, pendingVideosCount: 0),
                        .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0)
                    ])),
                devicePermissionHandler: MockDevicePermissionHandler(photoAuthorization: .limited, audioAuthorized: true, videoAuthorized: true))
        
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
            .values
            .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, true)
        XCTAssertEqual(sut.cameraUploadBannerStatusViewState, .uploadPartialCompleted(reason: .photoLibraryLimitedAccess))
    }
    
    func testCameraUploadStatusShown_whenStatusEqualsUploadPaused_shouldAutoShowBanner() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: makeCameraUploadSequence(entity: .init(progress: 1, pendingFilesCount: 1, pendingVideosCount: 0)),
                possiblePauseReason: .noWifi))
        
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .values
            .first(where: { $0 })
        
        XCTAssertEqual(result, true)
        XCTAssertEqual(sut.cameraUploadBannerStatusViewState, .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: 1)))
    }
    
    func testCameraUploadStatusShown_whenStatusEqualsInProgress_shouldReturnFalse() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: makeCameraUploadSequence(entity: .init(progress: 1, pendingFilesCount: 1, pendingVideosCount: 0)))
            )
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
             .values
             .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, false)
        XCTAssertEqual(sut.cameraUploadBannerStatusViewState, .uploadInProgress(numberOfFilesPending: 1))
    }
    
    func testCameraUploadStatusShown_whenStartingWithCompletedStatus_shouldNotAutoShowBanner() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: makeCameraUploadSequence(entities: [
                    .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0)
                ]))
        )
                
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
             .values
             .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, false)
        XCTAssertEqual(sut.cameraUploadBannerStatusViewState, .uploadCompleted)
    }
    
    func testCameraUploadStatusShown_whenStartingWithPartiallyCompletedStatus_shouldNotAutoShowBanner() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: makeCameraUploadSequence(entities: [
                    .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 1)
                ]))
        )
                
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
             .values
             .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, false)
        XCTAssertEqual(sut.cameraUploadBannerStatusViewState, .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 1)))
    }
}

extension CameraUploadStatusBannerViewModelTests {
    private func makeSUT(
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase(),
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler()
    ) -> CameraUploadStatusBannerViewModel {
        CameraUploadStatusBannerViewModel(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler,
            featureFlagProvider: MockFeatureFlagProvider(list: [.timelineCameraUploadStatus: true]))
    }
    
    private func makeCameraUploadSequence(entity: CameraUploadStatsEntity) -> AnyAsyncSequence<CameraUploadStatsEntity> {
        SingleItemAsyncSequence(item: entity)
            .eraseToAnyAsyncSequence()
    }

    private func makeCameraUploadSequence(entities: [CameraUploadStatsEntity]) -> AnyAsyncSequence<CameraUploadStatsEntity> {
        entities
            .publisher
            .values
            .eraseToAnyAsyncSequence()
    }
}
