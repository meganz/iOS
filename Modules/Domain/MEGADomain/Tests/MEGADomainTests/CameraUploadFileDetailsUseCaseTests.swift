import Foundation
import MEGADomain
import MEGADomainMock
import MEGAPreference
import Testing

struct CameraUploadFileDetailsUseCaseTests {
    @Test
    func fileDetails() async throws {
        let localIdentifier = "id"
        let expectedFiles = Set([CameraUploadFileDetailsEntity(localIdentifier: localIdentifier)])
        let repository = MockCameraUploadAssetRepository(
            fileDetailsResult: .success(expectedFiles)
        )
        let sut = Self.makeSUT(cameraUploadAssetRepository: repository)
        
        #expect(try await sut.fileDetails(forLocalIdentifiers: [localIdentifier]) == expectedFiles)
    }
    
    struct UploadFileName {
        let localIdentifier = "localIdentifier"
        let creationDate = Date(timeIntervalSince1970: 1762221484)
        
        @Test("uploadFileName generates correct filename with date format")
        func uploadFileNameGeneratesCorrectFilenameWithDateFormat() throws {
            let sut = makeSUT()
            let asset = CameraAssetUploadEntity(
                localIdentifier: localIdentifier,
                creationDate: creationDate,
                mediaType: .video)
            
            let fileName = try sut.uploadFileName(for: asset)
            
            #expect(fileName == "2025-11-04 14.58.04.mp4")
        }
        
        @Test("uploadFileName returns empty extension for unknown media type")
        func uploadFileNameReturnsEmptyExtensionForUnknownMediaType() throws {
            let sut = makeSUT()
            let asset = CameraAssetUploadEntity(
                localIdentifier: localIdentifier,
                creationDate: creationDate,
                mediaType: .unknown)
            
            #expect(throws: CameraUploadFileDetailsErrorEntity.invalidMediaType) {
                try sut.uploadFileName(for: asset)
            }
        }
        
        // MARK: - Image Extension Tests
        
        @Test("imageExtension returns live.mp4 for live photos")
        func imageExtensionReturnsLiveMp4ForLivePhotos() throws {
            let sut = makeSUT()
            let asset = CameraAssetUploadEntity(
                localIdentifier: localIdentifier,
                creationDate: creationDate,
                mediaType: .image,
                mediaSubType: .photoLive
            )
            
            let fileName = try sut.uploadFileName(for: asset)
            
            #expect(fileName == "2025-11-04 14.58.04.live.mp4")
        }
        
        @Test("imageExtension returns burst prefix for burst photos")
        func imageExtensionReturnsBurstPrefixForBurstPhotos() throws {
            let assetType = AssetMediaTypeEntity(mediaFormat: .jpeg, isBurst: true)
            let cameraUploadAssetRepository = MockCameraAssetTypeRepository(
                assetMediaType: assetType)
            
            let sut = makeSUT(
                cameraAssetTypeRepository: cameraUploadAssetRepository)
            let asset = CameraAssetUploadEntity(
                localIdentifier: localIdentifier,
                creationDate: creationDate,
                mediaType: .image)
            
            let fileName = try sut.uploadFileName(for: asset)
            
            #expect(fileName == "2025-11-04 14.58.04.burst.jpg")
        }
        
        @Test("imageExtension returns jpg for jpeg format")
        func imageExtensionReturnsJpgForJpegFormat() throws {
            let assetType = AssetMediaTypeEntity(mediaFormat: .jpeg, isBurst: false)
            let cameraUploadAssetRepository = MockCameraAssetTypeRepository(
                assetMediaType: assetType)
            
            let sut = makeSUT(
                cameraAssetTypeRepository: cameraUploadAssetRepository)
            let asset = CameraAssetUploadEntity(
                localIdentifier: localIdentifier,
                creationDate: creationDate,
                mediaType: .image)
            
            let fileName = try sut.uploadFileName(for: asset)
            
            #expect(fileName.hasSuffix(".jpg") == true)
        }
        
        @Test("imageExtension converts HEIC to JPG when preference is enabled")
        func imageExtensionConvertsHEICToJPGWhenPreferenceEnabled() throws {
            let preferenceRepository = MockPreferenceRepository()
            preferenceRepository[PreferenceKeyEntity.shouldConvertHEICPhoto.rawValue] = true
            
            let assetType = AssetMediaTypeEntity(mediaFormat: .heic, isBurst: false)
            let cameraUploadAssetRepository = MockCameraAssetTypeRepository(
                assetMediaType: assetType)
            
            let sut = makeSUT(
                cameraAssetTypeRepository: cameraUploadAssetRepository,
                preferenceRepository: preferenceRepository)
            let asset = CameraAssetUploadEntity(
                localIdentifier: localIdentifier,
                creationDate: creationDate,
                mediaType: .image)
            
            let fileName = try sut.uploadFileName(for: asset)
            
            #expect(fileName == "2025-11-04 14.58.04.jpg")
        }
        
        @Test("imageExtension keeps HEIC when preference is disabled")
        func imageExtensionKeepsHEICWhenPreferenceDisabled() throws {
            let preferenceRepository = MockPreferenceRepository()
            preferenceRepository[PreferenceKeyEntity.shouldConvertHEICPhoto.rawValue] = false
            
            let assetType = AssetMediaTypeEntity(mediaFormat: .heic, isBurst: false)
            let cameraUploadAssetRepository = MockCameraAssetTypeRepository(
                assetMediaType: assetType
            )
            
            let sut = makeSUT(
                cameraAssetTypeRepository: cameraUploadAssetRepository,
                preferenceRepository: preferenceRepository
            )
            let asset = CameraAssetUploadEntity(
                localIdentifier: localIdentifier,
                creationDate: creationDate,
                mediaType: .image)
            
            let fileName = try sut.uploadFileName(for: asset)
            
            #expect(fileName == "2025-11-04 14.58.04.heic")
        }
        
        @Test("imageExtension handles all supported formats",
              arguments: [
                (AssetMediaFormatEntity.jpeg, "jpg"),
                (.heif, "heif"),
                (.png, "png"),
                (.dng, "dng"),
                (.gif, "gif"),
                (.webp, "webp"),
                (.mp4, "mp4"),
                (.mov, "mov"),
                (.unknown(identifier: "custom"), "custom")
              ]
        )
        func imageExtensionHandlesAllSupportedFormats(
            mediaFormat: AssetMediaFormatEntity,
            expectedExtension: String
        ) throws {
            let assetType = AssetMediaTypeEntity(mediaFormat: mediaFormat, isBurst: false)
            let cameraAssetTypeRepository = MockCameraAssetTypeRepository(
                assetMediaType: assetType
            )
            
            let sut = makeSUT(
                cameraAssetTypeRepository: cameraAssetTypeRepository
            )
            let asset = CameraAssetUploadEntity(
                localIdentifier: localIdentifier,
                mediaType: .image
            )
            
            let fileName = try sut.uploadFileName(for: asset)
            
            #expect(fileName.hasSuffix(".\(expectedExtension)") == true, "Failed for format: \(mediaFormat)")
        }
        
        @Test
        func assetNotFound() async throws {
            let cameraAssetTypeRepository = MockCameraAssetTypeRepository(
                assetMediaType: nil
            )
            
            let sut = makeSUT(
                cameraAssetTypeRepository: cameraAssetTypeRepository
            )
            let asset = CameraAssetUploadEntity(
                localIdentifier: localIdentifier,
                mediaType: .image
            )
            
            #expect(throws: CameraUploadFileDetailsErrorEntity.assetNotFound) {
                try sut.uploadFileName(for: asset)
            }
        }
    }
    
    private static func makeSUT(
        cameraUploadAssetRepository: some CameraUploadAssetRepositoryProtocol = MockCameraUploadAssetRepository(),
        cameraAssetTypeRepository: some CameraAssetTypeRepositoryProtocol = MockCameraAssetTypeRepository(),
        preferenceRepository: some PreferenceRepositoryProtocol = MockPreferenceRepository()
    ) -> CameraUploadFileDetailsUseCase {
        .init(
            cameraUploadAssetRepository: cameraUploadAssetRepository,
            cameraAssetTypeRepository: cameraAssetTypeRepository,
            preferenceRepository: preferenceRepository
        )
    }
}
