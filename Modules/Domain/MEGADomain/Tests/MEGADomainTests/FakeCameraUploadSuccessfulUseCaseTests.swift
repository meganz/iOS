import MEGADomain
import XCTest

final class FakeCameraUploadSuccessfulUseCaseTests: XCTestCase {
    func testMonitorUploadStats_startMonitoring_shouldUpdateProgressTillComplete() async {
        let sut = FakeCameraUploadSuccessfulUseCase(photoUploadCount: 4,
                                                    initialDelayInNanoSeconds: 10,
                                                    delayBetweenItemsInNanoSeconds: 10)
        
        var iterator = sut.monitorUploadStatus.makeAsyncIterator()
        
        let expectedValues = [CameraUploadStatsEntity(progress: 0, pendingFilesCount: 4, pendingVideosCount: 0),
                              CameraUploadStatsEntity(progress: 0.25, pendingFilesCount: 3, pendingVideosCount: 0),
                              CameraUploadStatsEntity(progress: 0.5, pendingFilesCount: 2, pendingVideosCount: 0),
                              CameraUploadStatsEntity(progress: 0.75, pendingFilesCount: 1, pendingVideosCount: 0),
                              CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0, pendingVideosCount: 0)
        ]
        for (index, expected) in expectedValues.enumerated() {
            guard let result = await iterator.next() else {
                XCTFail("Iterator returned nil unexpectedly")
                break
            }
            switch result {
            case .success(let value):
                XCTAssertEqual(value.progress, expected.progress, accuracy: 0.1,
                               "Fail at index: \(index) with value: \(value)")
                XCTAssertEqual(value.pendingFilesCount, expected.pendingFilesCount,
                               "Fail at index: \(index) with value: \(value)")
            case .failure:
                XCTFail("Unexpected error")
            }
           
        }
        let uploadComplete = await iterator.next()
        XCTAssertNil(uploadComplete)
    }
}
