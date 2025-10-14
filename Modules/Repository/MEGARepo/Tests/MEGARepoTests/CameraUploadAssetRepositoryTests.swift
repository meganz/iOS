import Foundation
import MEGADomain
@testable import MEGARepo
import MEGARepoMock
import Testing

struct CameraUploadAssetRepositoryTests {
    private let identifier = UUID().uuidString
    
    @Test func uploads() async throws {
        let records = [
            AssetUploadRecordDTO(
                localIdentifier: identifier,
                creationDate: Date.now,
                mediaType: .image,
                mediaSubtypes: nil,
                additionalMediaSubtypes: nil,
                status: .notStarted)
        ]
        
        let sut = Self.makeSUT(
            cameraUploadRecordStore: MockCameraUploadRecordStore(
                assetUploadsResult: .success(records)
            ))
        
        let result = try await sut.uploads(
            startingFrom: identifier,
            isForward: true,
            limit: nil,
            statuses: [.notStarted],
            mediaTypes: [.image])
        
        #expect(result == records.toAssetUploadRecordEntities())
    }
    
    @Test func fileDetails() async throws {
        let records = [
            AssetUploadFileNameRecordDTO(
                localIdentifier: identifier,
                localUniqueFileName: "Test",
                fileExtension: "jpg")
        ]
        let sut = Self.makeSUT(
            cameraUploadRecordStore: MockCameraUploadRecordStore(
                fileNamesResult: .success(records)
            )
        )
        let results = try await sut.fileDetails(forLocalIdentifiers: [identifier])
        
        #expect(results == records.toCameraUploadFileDetailsEntities())
    }
    
    private static func makeSUT(
        cameraUploadRecordStore: some CameraUploadRecordStore = MockCameraUploadRecordStore()
    ) -> CameraUploadAssetRepository {
        .init(cameraUploadRecordStore: cameraUploadRecordStore)
    }
}
