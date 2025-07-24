@testable import MEGA
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGASwift
import XCTest

final class MonitorCameraUploadBannerStatusProviderTests: XCTestCase {
    
    // MARK: CameraUploadBannerStatus
    func testMonitorCameraUploadBannerStatusSequence_whenItContainsPendingFiles_shouldReturnUploadInProgress() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence))
        
        let result = await sut.monitorCameraUploadBannerStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadInProgress(numberOfFilesPending: 10))
    }
    
    func testMonitorCameraUploadBannerStatusSequence_whenItContainsPendingFilesAndNoWifiInternet_shouldReturnUploadPausedNoWifi() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .noWifi
            ))
        
        let result = await sut.monitorCameraUploadBannerStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPaused(reason: .noWifiConnection))
    }
    
    func testMonitorCameraUploadBannerStatusSequence_whenItContainsPendingFilesAndNoNetworkConnectivity_shouldReturnUploadPausednoInternetConnection() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .noNetworkConnectivity
            ))
        
        let result = await sut.monitorCameraUploadBannerStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPaused(reason: .noInternetConnection))
    }
    
    func testMonitorCameraUploadBannerStatusSequence_whenItContainsPendingFilesAndNoWifiInternetButHasMobileDataAvailableAndEnabled_shouldReturnInProgress() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .notPaused
            ))
        
        let result = await sut.monitorCameraUploadBannerStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadInProgress(numberOfFilesPending: 10))
    }
    
    func testMonitorCameraUploadBannerStatusSequence_whenItContainsPendingFilesAndNoInternetAvailableAndMobileDataUploadEnabled_shouldReturnUploadPaused() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .noWifi))
        
        let result = await sut.monitorCameraUploadBannerStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPaused(reason: .noWifiConnection))
    }
    
    func testMonitorCameraUploadBannerStatusSequence_whenNoPendingFilesAndNoWifi_shouldReturnUploadCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .noWifi
            ))
        
        let result = await sut.monitorCameraUploadBannerStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadCompleted)
    }
    
    func testMonitorCameraUploadBannerStatusSequence_whenNoPendingFilesAndVideoUploadDisabledWithPendingFiles_shouldReturnUploadPartiallyCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 12)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence))
        
        let result = await sut.monitorCameraUploadBannerStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 12)))
    }
    
    func testMonitorCameraUploadBannerStatusSequence_whenNoPendingFilesAndPhotoLibraryAccessIsLimited_shouldReturnUploadPartiallyCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 12)).eraseToAnyAsyncSequence()
        let devicePermissionHandler = MockDevicePermissionHandler(photoAuthorization: .limited, audioAuthorized: true, videoAuthorized: true)

        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence),
            devicePermissionHandler: devicePermissionHandler)
        
        let result = await sut.monitorCameraUploadBannerStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPartialCompleted(reason: .photoLibraryLimitedAccess))
    }
    
    func testMonitorCameraUploadBannerStatusSequence_whenNoPendingFilesAndVideoUploadDisabledWithPendingFilesAndPhotoLibraryAccessIsLimited_shouldReturnUploadPartiallyCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 12)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence))
        
        let result = await sut.monitorCameraUploadBannerStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadPartialCompleted(reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: 12)))
    }
    
    // MARK: CameraUploadStatus
    func testMonitorCameraUploadImageStatusSequence_whenItContainsPendingFiles_shouldReturnUploadInProgress() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 0.5, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence))
        
        let result = await sut.monitorCameraUploadImageStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploading(progress: 0.5))
    }
    
    func testMonitorCameraUploadImageStatusSequence_whenItContainsPendingFilesAndNoWifiInternet_shouldReturnWarning() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 0.5, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .noWifi
            ))
        
        let result = await sut.monitorCameraUploadImageStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .warning)
    }
    
    func testMonitorCameraUploadImageStatusSequence_whenItContainsPendingFilesAndNoWifiInternetButHasMobileDataAvailableAndEnabled_shouldReturnInProgress() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .notPaused
            ))
        
        let result = await sut.monitorCameraUploadBannerStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .uploadInProgress(numberOfFilesPending: 10))
    }
    
    func testMonitorCameraUploadImageStatusSequence_whenItContainsPendingFilesAndNoInternetAvailableAndMobileDataUploadEnabled_shouldReturnWarning() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 10, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .noWifi))
        
        let result = await sut.monitorCameraUploadImageStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .warning)
    }
    
    func testMonitorCameraUploadStatusSequence_whenNoPendingFilesAndNoWifi_shouldReturnCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStats: uploadAsyncSequence,
                possiblePauseReason: .noWifi
            ))
        
        let result = await sut.monitorCameraUploadImageStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .completed)
    }
    
    func testMonitorCameraUploadStatusSequence_whenNoPendingFilesAndVideoUploadDisabledWithPendingFiles_shouldReturnCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 12)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence))
        
        let result = await sut.monitorCameraUploadImageStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .completed)
    }
    
    func testMonitorCameraUploadStatusSequence_whenNoPendingFilesAndPhotoLibraryAccessIsLimited_shouldReturnCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 12)).eraseToAnyAsyncSequence()
        let devicePermissionHandler = MockDevicePermissionHandler(photoAuthorization: .limited, audioAuthorized: true, videoAuthorized: true)

        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence),
            devicePermissionHandler: devicePermissionHandler)
        
        let result = await sut.monitorCameraUploadImageStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .completed)
    }
    
    func testMonitorCameraUploadStatusSequence_whenNoPendingFilesAndVideoUploadDisabledWithPendingFilesAndPhotoLibraryAccessIsLimited_shouldReturnCompleted() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 12)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence))
        
        let result = await sut.monitorCameraUploadImageStatusSequence().first(where: { _ in true})
        
        XCTAssertEqual(result, .completed)
    }
}

extension MonitorCameraUploadBannerStatusProviderTests {
    private func makeSUT(
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase(),
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler()
    ) -> MonitorCameraUploadStatusProvider {
        MonitorCameraUploadStatusProvider(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler)
    }
}
