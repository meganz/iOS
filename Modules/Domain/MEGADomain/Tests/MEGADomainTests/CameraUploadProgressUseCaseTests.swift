import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

struct CameraUploadProgressUseCaseTests {
    @Test
    func cameraUploadPhaseEventUpdates() async {
        let phaseEvent = CameraUploadPhaseEventEntity(
            assetIdentifier: "local", phase: .completed)
        
        let cameraUploadPhaseEventUpdates = SingleItemAsyncSequence(item: phaseEvent)
            .eraseToAnyAsyncSequence()
        
        let sut = Self.makeSUT(
            transferProgressRepository: MockCameraUploadTransferProgressRepository(
                cameraUploadPhaseEventUpdates: cameraUploadPhaseEventUpdates
            )
        )
        
        var asyncIterator = await sut.cameraUploadPhaseEventUpdates.makeAsyncIterator()
        
        #expect(await asyncIterator.next() == phaseEvent)
    }
    
    @Test
    func activeCameraUploadAssets() async throws {
        let inProgressIdentifier: CameraUploadLocalIdentifierEntity = "localIdentifier"
        let registeredIdentifier: CameraUploadLocalIdentifierEntity = "registered-localIdentifier"
        let activeUploads: [CameraUploadLocalIdentifierEntity] = [inProgressIdentifier, registeredIdentifier]
        let rawData = CameraUploadTaskProgressRawDataEntity(
            totalBytesSent: 50, totalBytesExpected: 100, speedSamples: [])
        let expectedFiles = [
            CameraUploadFileDetailsEntity(
                localIdentifier: inProgressIdentifier,
                fileName: "im-uploading", fileExtension: "jpg")
        ]
        let cameraUploadAssetRepository = MockCameraUploadAssetRepository(
            fileDetailsResult: .success(Set(expectedFiles))
        )
        let sut = Self.makeSUT(
            cameraUploadAssetRepository: cameraUploadAssetRepository,
            transferProgressRepository: MockCameraUploadTransferProgressRepository(
                activeUploads: activeUploads,
                progressRawDataForIdentifier: [inProgressIdentifier: rawData]
            )
        )
        
        #expect(try await sut.inProgressFiles() == expectedFiles)
    }
    
    @Test(arguments: zip([
        // No progress (0%)
        CameraUploadTaskProgressRawDataEntity(
            totalBytesSent: 0,
            totalBytesExpected: 300,
            speedSamples: []),
        // Partial Progress
        CameraUploadTaskProgressRawDataEntity(
            totalBytesSent: 90,
            totalBytesExpected: 300,
            speedSamples: [
                .init(timestamp: try "2025-10-24T10:00:00Z".date,
                      bytesSent: 500_000),
                .init(timestamp: try "2025-10-24T10:00:05Z".date,
                      bytesSent: 1_200_000)
            ]),
        // Multiple chunks with varying progress and detailed speed samples
        CameraUploadTaskProgressRawDataEntity(
            totalBytesSent: 1150,
            totalBytesExpected: 3000,
            speedSamples: [
                .init(timestamp: try "2025-10-24T10:00:00Z".date,
                      bytesSent: 0),
                .init(timestamp: try "2025-10-24T10:00:05Z".date,
                      bytesSent: 300_000),
                .init(timestamp: try "2025-10-24T10:00:10Z".date,
                      bytesSent: 750_000),
                .init(timestamp: try "2025-10-24T10:00:20Z".date,
                      bytesSent: 950_000),
                .init(timestamp: try "2025-10-24T10:00:30Z".date,
                      bytesSent: 1_150_000)
            ]),
        // Complete Progress
        CameraUploadTaskProgressRawDataEntity(
            totalBytesSent: 300,
            totalBytesExpected: 300,
            speedSamples: [
                .init(timestamp: try "2025-10-24T10:00:00Z".date,
                      bytesSent: 1_000_000),
                .init(timestamp: try "2025-10-24T10:00:10Z".date,
                      bytesSent: 2_000_000)
            ])
    ], [
        // Expected result for No Progress
        CameraUploadProgressEntity(
            percentage: 0.0,
            totalBytes: 300,
            bytesPerSecond: 0),
        // Expected result for Partial Progress
        CameraUploadProgressEntity(
            percentage: 0.3,
            totalBytes: 300,
            bytesPerSecond: 140_000),
        // Expected result for multiple chunks with varying progress and detailed speed samples
        CameraUploadProgressEntity(
            percentage: 0.3833,
            totalBytes: 3000,
            bytesPerSecond: 47_500),
        // Expected result for complete Progress
        CameraUploadProgressEntity(
            percentage: 1.0,
            totalBytes: 300,
            bytesPerSecond: 100_000)
    ]))
    func progressUpdates(
        rawData: CameraUploadTaskProgressRawDataEntity,
        expectedProgress: CameraUploadProgressEntity
    ) async throws {
        let localIdentifier = "localIdentifier"
        let progressRawDataAsyncSequence = SingleItemAsyncSequence(
            item: rawData).eraseToAnyAsyncSequence()
        
        let sut = Self.makeSUT(
            transferProgressRepository: MockCameraUploadTransferProgressRepository(
                progressRawDataForIdentifier: [localIdentifier: rawData],
                progressRawDataUpdates: progressRawDataAsyncSequence
            )
        )
        
        var asyncIterator = await sut.uploadProgressUpdates(for: localIdentifier)
            .makeAsyncIterator()
        #expect(await asyncIterator.next() == expectedProgress)
        
        #expect(await sut.uploadProgress(for: localIdentifier) == expectedProgress)
    }
    
    private static func makeSUT(
        cameraUploadAssetRepository: some CameraUploadAssetRepositoryProtocol = MockCameraUploadAssetRepository(),
        transferProgressRepository: some CameraUploadTransferProgressRepositoryProtocol = MockCameraUploadTransferProgressRepository()
    ) -> CameraUploadProgressUseCase {
        .init(
            cameraUploadAssetRepository: cameraUploadAssetRepository,
            transferProgressRepository: transferProgressRepository)
    }
}

extension CameraUploadProgressEntity: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.percentage.isApproximatelyEqual(to: rhs.percentage, tolerance: 0.01) &&
        lhs.totalBytes == rhs.totalBytes &&
        lhs.bytesPerSecond.isApproximatelyEqual(to: rhs.bytesPerSecond, tolerance: 1024.0)
    }
}
