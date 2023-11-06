import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import SwiftUI
import XCTest

final class CameraUploadStatusButtonViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testMonitorCameraUpload_noUpdates_shouldSetToSync() async {
        let uploadAsyncSequence = EmptyAsyncSequence<CameraUploadStatsEntity>()
            .eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStatus: uploadAsyncSequence))
        
        await sut.monitorCameraUpload()
        
        XCTAssertEqual(sut.imageViewModel.status, .checkPendingItemsToUpload)
    }
    
    func testMonitorCameraUpload_onPendingFiles_shouldUpdateProgress() async {
        let progress: Float = 0.55
        let uploadAsyncSequence = SingleItemAsyncSequence(item: CameraUploadStatsEntity(progress: progress, pendingFilesCount: 5))
            .eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStatus: uploadAsyncSequence))
        
        await sut.monitorCameraUpload()
        
        XCTAssertEqual(sut.imageViewModel.status, .uploading(progress: progress))
    }
    
    func testMonitorCameraUpload_onNoPendingFiles_shouldSetStatusAsComplete() async {
        let uploadAsyncSequence = SingleItemAsyncSequence(item: CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0))
            .eraseToAnyAsyncSequence()
        let sut = makeSUT(monitorCameraUploadUseCase: MockMonitorCameraUploadUseCase(monitorUploadStatus: uploadAsyncSequence))
        
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
        
        XCTAssertEqual(sut.imageViewModel.status, .completed)
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(statuses, [.checkPendingItemsToUpload, .completed])
    }
    
    private func makeSUT(
        monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol = MockMonitorCameraUploadUseCase()
    ) -> CameraUploadStatusButtonViewModel {
        CameraUploadStatusButtonViewModel(monitorCameraUploadUseCase: monitorCameraUploadUseCase)
    }
}
