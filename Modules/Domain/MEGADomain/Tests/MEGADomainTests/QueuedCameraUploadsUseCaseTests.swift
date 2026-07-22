import MEGADomain
import MEGADomainMock
import MEGAPreference
import Testing

struct QueuedCameraUploadsUseCaseTests {
    private let expectedStatuses: [CameraAssetUploadStatusEntity] = [
        .notStarted, .notReady, .processing, .queuedUp, .cancelled, .failed]
    
    @Test
    func cameraUploadDisabled() async throws {
        let preferenceRepository = MockPreferenceRepository()
        preferenceRepository[PreferenceKeyEntity.isCameraUploadsEnabled.rawValue] = false
        
        let sut = Self.makeSUT(
            preferenceRepository: preferenceRepository
        )
        
        let result = try await sut.queuedCameraUploads(
            startingFrom: nil,
            isForward: true,
            limit: 20)
        
        #expect(result.isEmpty)
    }
    
    @Test(arguments: [
        (Optional<QueuedCameraUploadCursorEntity>.none, true, Optional<Int>.none, true, [PhotoAssetMediaTypeEntity.image, .video]),
        (.init(localIdentifier: "test", creationDate: .now), false, 20, false, [.image])
    ])
    func queuedUploads(
        startingFrom cursor: QueuedCameraUploadCursorEntity?,
        isForward: Bool,
        limit: Int?,
        isVideoUploadEnabled: Bool,
        expectedMediaTypes: [PhotoAssetMediaTypeEntity]
    ) async throws {
        let expected = [CameraAssetUploadEntity(localIdentifier: "localIdentifier")]
        let cameraUploadAssetRepository = MockCameraUploadAssetRepository(
            uploadsResult: .success(expected)
        )
        let preferenceRepository = MockPreferenceRepository()
        preferenceRepository[PreferenceKeyEntity.isCameraUploadsEnabled.rawValue] = true
        preferenceRepository[PreferenceKeyEntity.isVideoUploadEnabled.rawValue] = isVideoUploadEnabled
        
        let sut = Self.makeSUT(
            cameraUploadAssetRepository: cameraUploadAssetRepository,
            preferenceRepository: preferenceRepository
        )
        
        let result = try await sut.queuedCameraUploads(
            startingFrom: cursor,
            isForward: isForward,
            limit: limit)
        
        #expect(result == expected)
        #expect(cameraUploadAssetRepository.invocations == [
            .uploads(startingFrom: cursor,
                     isForward: isForward,
                     limit: limit,
                     statuses: expectedStatuses,
                     mediaTypes: expectedMediaTypes)
        ])
    }

    @Test
    func failedUploadsCountReturnsZeroWhenCameraUploadDisabled() async throws {
        let preferenceRepository = MockPreferenceRepository()
        preferenceRepository[PreferenceKeyEntity.isCameraUploadsEnabled.rawValue] = false

        let sut = Self.makeSUT(preferenceRepository: preferenceRepository)

        #expect(try await sut.failedUploadsCount() == 0)
    }

    @Test
    func failedUploadsCountFetchesOnlyFailedRecordsAndReturnsTheirCount() async throws {
        let failedRecords = [
            CameraAssetUploadEntity(localIdentifier: "failed-1", status: .failed),
            CameraAssetUploadEntity(localIdentifier: "failed-2", status: .failed)
        ]
        let cameraUploadAssetRepository = MockCameraUploadAssetRepository(
            uploadsResult: .success(failedRecords)
        )
        let preferenceRepository = MockPreferenceRepository()
        preferenceRepository[PreferenceKeyEntity.isCameraUploadsEnabled.rawValue] = true
        preferenceRepository[PreferenceKeyEntity.isVideoUploadEnabled.rawValue] = false

        let sut = Self.makeSUT(
            cameraUploadAssetRepository: cameraUploadAssetRepository,
            preferenceRepository: preferenceRepository
        )

        #expect(try await sut.failedUploadsCount() == 2)
        // Only `.failed` records are fetched — the cost does not scale with the whole queue.
        #expect(cameraUploadAssetRepository.invocations == [
            .uploads(startingFrom: nil,
                     isForward: true,
                     limit: nil,
                     statuses: [.failed],
                     mediaTypes: [.image])
        ])
    }

    private static func makeSUT(
        cameraUploadAssetRepository: some CameraUploadAssetRepositoryProtocol = MockCameraUploadAssetRepository(),
        preferenceRepository: some PreferenceRepositoryProtocol = MockPreferenceRepository()
    ) -> QueuedCameraUploadsUseCase {
        .init(
            cameraUploadAssetRepository: cameraUploadAssetRepository,
            preferenceRepository: preferenceRepository)
    }
}
