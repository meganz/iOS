@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentationMock
import MEGASwift
import XCTest

final class MonitorCameraUploadBannerStatusProviderTests: XCTestCase {
    
    func testMonitorCameraUploadStatusSequence_whenItContainsPendingFiles_shouldReturnUploadInProgress() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence))
        
        let result = await sut.monitorCameraUploadStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadInProgress(numberOfFilesPending: 10))
    }
    
    func testMonitorCameraUploadStatusSequence_whenItContainsPendingFilesAndNoWifiInternet_shouldReturnUploadPausedNoWifi() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .noWifi
            ))
        
        let result = await sut.monitorCameraUploadStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: 10)))
    }
    
    func testMonitorCameraUploadStatusSequence_whenItContainsPendingFilesAndNoWifiInternetButHasMobileDataAvailableAndEnabled_shouldReturnInProgress() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .notPaused
            ))
        
        let result = await sut.monitorCameraUploadStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadInProgress(numberOfFilesPending: 10))
    }
    
    func testMonitorCameraUploadStatusSequence_whenItContainsPendingFilesAndNoInternetAvailableAndMobileDataUploadEnabled_shouldReturnInProgress() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .noWifi))
        
        let result = await sut.monitorCameraUploadStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: 10)))
    }
    
    func testMonitorCameraUploadStatusSequence_whenNoPendingFilesAndNoWifi_shouldReturnUploadCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .noWifi
            ))
        
        let result = await sut.monitorCameraUploadStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadCompleted)
    }
    
    func testMonitorCameraUploadStatusSequence_whenNoPendingFilesAndVideoUploadDisabledWithPendingFiles_shouldReturnUploadPartiallyCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 12)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence))
        
        let result = await sut.monitorCameraUploadStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 12)))
    }
    
    func testMonitorCameraUploadStatusSequence_whenNoPendingFilesAndPhotoLibraryAccessIsLimited_shouldReturnUploadPartiallyCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 12)).eraseToAnyAsyncSequence()
        let devicePermissionHandler = MockDevicePermissionHandler(photoAuthorization: .limited, audioAuthorized: true, videoAuthorized: true)

        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence),
            devicePermissionHandler: devicePermissionHandler)
        
        let result = await sut.monitorCameraUploadStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPartialCompleted(reason: .photoLibraryLimitedAccess))
    }
    
    func testMonitorCameraUploadStatusSequence_whenNoPendingFilesAndVideoUploadDisabledWithPendingFilesAndPhotoLibraryAccessIsLimited_shouldReturnUploadPartiallyCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 12)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence))
        
        let result = await sut.monitorCameraUploadStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 12)))
    }
}

extension MonitorCameraUploadBannerStatusProviderTests {
    private func makeSUT(
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase(),
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler()
    ) -> MonitorCameraUploadBannerStatusProvider {
        MonitorCameraUploadBannerStatusProvider(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler)
    }
}
