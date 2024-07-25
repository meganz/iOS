import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGASwift
import SwiftUI
import XCTest

final class CameraUploadStatusButtonViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    @MainActor
    func testInit_cameraUploadsEnabledState_shouldSetStatusToCorrectly() {
        [(cameraUploadEnabled: false, status: CameraUploadStatus.turnedOff),
         (cameraUploadEnabled: true, status: CameraUploadStatus.checkPendingItemsToUpload)].forEach {
            let sut = makeSUT(preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: $0.cameraUploadEnabled]))
            
            XCTAssertEqual(sut.imageViewModel.status, $0.status)
        }
    }
    
    @MainActor
    func testMonitorCameraUpload_noUpdates_shouldSetToCheckPendingItemsToUploadAndThenIdle() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0))
            .eraseToAnyAsyncSequence()
        let sut = makeSUT(idleWaitTimeNanoSeconds: 100_000,
                          monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence),
                          preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true]))
        
        XCTAssertEqual(sut.imageViewModel.status, .checkPendingItemsToUpload)
        
        let exp = XCTestExpectation(description: "Status updates")
        sut.imageViewModel.$status
            .removeDuplicates()
            .dropFirst()
            .sink {
                XCTAssertEqual($0, .idle)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        await sut.monitorCameraUpload()
        
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    @MainActor
    func testMonitorCameraUpload_noUpdatesAndLimitedLibraryAccess_shouldSetToCheckPendingItemsToUploadAndThenWarning() async {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0))
            .eraseToAnyAsyncSequence()
        let sut = makeSUT(idleWaitTimeNanoSeconds: 100_000,
                          monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence),
                          preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true]),
                          devicePermissionHandler: MockDevicePermissionHandler(photoAuthorization: .limited, audioAuthorized: false, videoAuthorized: false))
        
        XCTAssertEqual(sut.imageViewModel.status, .checkPendingItemsToUpload)
        
        let exp = XCTestExpectation(description: "Status updates")
        sut.imageViewModel.$status
            .removeDuplicates()
            .dropFirst()
            .sink {
                XCTAssertEqual($0, .warning)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        await sut.monitorCameraUpload()
        
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    @MainActor
    func testMonitorCameraUpload_onPendingFiles_shouldUpdateProgress() async {
        let progress: Float = 0.55
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: progress, pendingFilesCount: 5, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence),
                          preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true]))
        
        await sut.monitorCameraUpload()
        
        XCTAssertEqual(sut.imageViewModel.status, .uploading(progress: progress))
    }
    
    @MainActor
    func testMonitorCameraUpload_onNoPendingFiles_shouldSetStatusAsCheckingThenIdle() async throws {
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(idleWaitTimeNanoSeconds: 100_000_000,
                          monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence),
                          preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true]))
        
        XCTAssertEqual(sut.imageViewModel.status, .checkPendingItemsToUpload)
        
        let exp = XCTestExpectation(description: "Status updates")
        exp.expectedFulfillmentCount = 2
        
        var statuses = [CameraUploadStatus]()
        sut.imageViewModel.$status
            .dropFirst()
            .sink {
                statuses.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        await sut.monitorCameraUpload()
        
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(statuses, [.checkPendingItemsToUpload, .idle])
    }
        
    @MainActor
    func testOnMonitorCameraUpload_preferenceChanged_shouldUpdateImageStatus() async {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        XCTAssertEqual(sut.imageViewModel.status, .checkPendingItemsToUpload)
    
        preferenceUseCase[.isCameraUploadsEnabled] = false
        
        await sut.monitorCameraUpload()
        
        XCTAssertEqual(sut.imageViewModel.status, .turnedOff)
    }
    
    @MainActor
    private func makeSUT(
        idleWaitTimeNanoSeconds: UInt64 = 1_000_000_000,
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase(),
        devicePermissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler()
    ) -> CameraUploadStatusButtonViewModel {
        CameraUploadStatusButtonViewModel(
            idleWaitTimeNanoSeconds: idleWaitTimeNanoSeconds,
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            devicePermissionHandler: devicePermissionHandler,
            preferenceUseCase: preferenceUseCase)
    }
}
