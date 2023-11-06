import MEGADomain
import XCTest

final class FakeCameraUploadSuccessfulUseCaseTests: XCTestCase {
    func testMonitorUploadStats_startMonitoring_shouldUpdateProgressTillComplete() async {
        let sut = FakeCameraUploadSuccessfulUseCase(photoUploadCount: 4,
                                              initialDelayInNanoSeconds: 10)
        
        var iterator = sut.monitorUploadStatus.makeAsyncIterator()
        
        let expectedValues = [CameraUploadStatsEntity(progress: 0, pendingFilesCount: 4),
                              CameraUploadStatsEntity(progress: 0.25, pendingFilesCount: 3),
                              CameraUploadStatsEntity(progress: 0.5, pendingFilesCount: 2),
                              CameraUploadStatsEntity(progress: 0.75, pendingFilesCount: 1),
                              CameraUploadStatsEntity(progress: 1.0, pendingFilesCount: 0)
        ]
        for expected in expectedValues {
            guard let value = await iterator.next() else {
                XCTFail("Iterator returned nil unexpectedly")
                break
            }
            XCTAssertEqual(value.progress, expected.progress, accuracy: 0.1)
            XCTAssertEqual(value.pendingFilesCount, expected.pendingFilesCount)
        }
        let uploadComplete = await iterator.next()
        XCTAssertNil(uploadComplete)
    }
}
