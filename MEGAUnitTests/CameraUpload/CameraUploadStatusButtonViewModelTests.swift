import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import SwiftUI
import XCTest

final class CameraUploadStatusButtonViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testInit_cameraUploadsEnabledState_shouldSetStatusToCorrectly() {
        [(cameraUploadEnabled: false, status: CameraUploadStatus.turnedOff),
         (cameraUploadEnabled: true, status: CameraUploadStatus.checkPendingItemsToUpload)].forEach {
            let sut = makeSUT(preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: $0.cameraUploadEnabled]))
            
            XCTAssertEqual(sut.imageViewModel.status, $0.status)
        }
    }
    
    func testMonitorCameraUpload_noUpdates_shouldSetToCheckPendingItemsToUploadAndThenIdle() async {
        let uploadAsyncSequence = EmptyAsyncSequence<CameraUploadStatsEntity>()
            .eraseToAnyAsyncSequence()
        let sut = makeSUT(idleWaitTimeNanoSeconds: 100_000,
                          monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence),
                          preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true]))
        
        XCTAssertEqual(sut.imageViewModel.status, .checkPendingItemsToUpload)
        
        let exp = XCTestExpectation(description: "Status updates")
        sut.imageViewModel.$status
            .dropFirst()
            .sink {
                XCTAssertEqual($0, .idle)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        await sut.monitorCameraUpload()
        
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    func testMonitorCameraUpload_onPendingFiles_shouldUpdateProgress() async {
        let progress: Float = 0.55
        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
            item: CameraUploadStatsEntity(progress: progress, pendingFilesCount: 5, pendingVideosCount: 0)).eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence),
                          preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true]))
        
        await sut.monitorCameraUpload()
        
        XCTAssertEqual(sut.imageViewModel.status, .uploading(progress: progress))
    }
    
    func testMonitorCameraUpload_onNoPendingFiles_shouldSetStatusAsCompleteAndIdle() async throws {
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
        XCTAssertEqual(statuses, [.completed, .idle])
    }
    
    func testMonitorCameraUpload_onUploadFailure_shouldSetStatusToWarning() async {
        // Will  be done in https://jira.developers.mega.co.nz/browse/CC-6223
        
//        let uploadAsyncSequence = SingleItemAsyncSequence<CameraUploadStatsEntity>(
//            item: .failure(GenericErrorEntity())).eraseToAnyAsyncSequence()
//        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStats: uploadAsyncSequence),
//                          preferenceUseCase: MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true]))
//        
//        XCTAssertEqual(sut.imageViewModel.status, .checkPendingItemsToUpload)
//        
//        await sut.monitorCameraUpload()
//        
//        XCTAssertEqual(sut.imageViewModel.status, .warning)
    }
    
    func testOnViewAppear_preferenceChanged_shouldUpdateImageStatus() {
        let preferenceUseCase = MockPreferenceUseCase(dict: [.isCameraUploadsEnabled: true])
        let sut = makeSUT(preferenceUseCase: preferenceUseCase)
        XCTAssertEqual(sut.imageViewModel.status, .checkPendingItemsToUpload)
        
        preferenceUseCase[.isCameraUploadsEnabled] = false
        
        sut.onViewAppear()
        
        XCTAssertEqual(sut.imageViewModel.status, .turnedOff)
    }
    
    private func makeSUT(
        idleWaitTimeNanoSeconds: UInt64 = 1_000_000_000,
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase()
    ) -> CameraUploadStatusButtonViewModel {
        CameraUploadStatusButtonViewModel(
            idleWaitTimeNanoSeconds: idleWaitTimeNanoSeconds,
            monitorCameraUploadUseCase: monitorCameraUploadUseCase,
            preferenceUseCase: preferenceUseCase)
    }
}
