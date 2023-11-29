@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentationMock
import MEGASwift
import XCTest

final class CameraUploadStatusBannerViewModelTests: XCTestCase {
    
    func testCameraUploadStatusShown_whenStatusEqualsCompleted_shouldReturnTrue() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStatus: makeCameraUploadSequence(entity: .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0)))
        )
                
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
             .values
             .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, true)
    }
    
    func testCameraUploadStatusShown_whenStatusEqualsPartiallyCompletedDueToVideoUploadsPending_shouldReturnTrue() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStatus: makeCameraUploadSequence(entity: .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 1)))
        )
                
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
             .values
             .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, true)
    }
    
    func testCameraUploadStatusShown_whenStatusEqualsPartiallyCompletedDueToLimitedAccessToPhotoLibrary_shouldReturnTrue() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStatus: makeCameraUploadSequence(entity: .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0))),
            devicePermissionHandler: MockDevicePermissionHandler(photoAuthorization: .limited, audioAuthorized: true, videoAuthorized: true))
                
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
             .values
             .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, true)
    }

    func testCameraUploadStatusShown_whenStatusEqualsUploadPuased_shouldReturnTrue() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStatus: makeCameraUploadSequence(entity: .init(progress: 1, pendingFilesCount: 1, pendingVideosCount: 0))),
            networkMonitorUseCase: MockNetworkMonitorUseCase(connectedViaWiFi: false))
        
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
            .values
            .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, true)
    }
    
    func testCameraUploadStatusShown_whenStatusEqualsInProgress_shouldReturnFalse() async throws {
        let sut = makeSUT(
            monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(
                monitorUploadStatus: makeCameraUploadSequence(entity: .init(progress: 1, pendingFilesCount: 1, pendingVideosCount: 0)))
            )
        try await sut.monitorCameraUploadStatus()
        
        let result = await sut.$cameraUploadStatusShown
            .collect(.byTime(DispatchQueue.main, .seconds(1)))
             .values
             .first(where: { _ in true })?.last
        
        XCTAssertEqual(result, false)
    }
}

extension CameraUploadStatusBannerViewModelTests {
    private func makeSUT(
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase(),
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(connectedViaWiFi: true),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(dict: [.cameraUploadsCellularDataUsageAllowed: false]),
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler()
    ) -> CameraUploadStatusBannerViewModel {
        CameraUploadStatusBannerViewModel(
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            preferenceUseCase: preferenceUseCase,
            devicePermissionHandler: devicePermissionHandler,
            featureFlagProvider: MockFeatureFlagProvider(list: [.timelineCameraUploadStatus: true]))
    }
    
    private func makeCameraUploadSequence(entity: CameraUploadStatsEntity) -> AnyAsyncSequence<Result<CameraUploadStatsEntity, Error>> {
        SingleItemAsyncSequence<Result<CameraUploadStatsEntity, Error>>(item: .success(entity))
            .eraseToAnyAsyncSequence()
    }
}
