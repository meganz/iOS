@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

struct CameraUploadProgressTableViewModelTests {
    @MainActor
    @Test func initialInProgressViewModels() async {
        let assetIdentifier = "localIdentifier"
        let fileEntity = CameraUploadFileDetailsEntity(localIdentifier: assetIdentifier)
        let cameraUploadProgressUseCase = MockCameraUploadProgressUseCase(
            inProgressFilesResult: .success([fileEntity])
        )
        let photoLibraryThumbnailUseCase = MockPhotoLibraryThumbnailUseCase()
        let thumbnailSize = CGSize(width: 32, height: 32)
        let sut = Self.makeSUT(
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase
        )
        
        await sut.loadInitial()
        
        #expect(sut.inProgressSnapshotUpdate == .initialLoad([.init(
            fileEntity: fileEntity,
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            thumbnailSize: thumbnailSize)]))
        #expect(photoLibraryThumbnailUseCase.invocations == [.startCaching(identifiers: [assetIdentifier], targetSize: thumbnailSize)])
    }
    
    @MainActor
    struct PPhaseEventUpdates {
        private let assetIdentifier = "localIdentifier"
        private let thumbnailSize = CGSize(width: 32, height: 32)
        
        @Test("Uploading should retrieve file details and add to in Progress")
        func uploading() async {
            let phaseEvent = CameraUploadPhaseEventEntity(
                assetIdentifier: assetIdentifier, phase: .uploading)
            let fileEntity = CameraUploadFileDetailsEntity(localIdentifier: assetIdentifier)
            let cameraUploadProgressUseCase = MockCameraUploadProgressUseCase(
                cameraUploadPhaseEventUpdates: SingleItemAsyncSequence(
                    item: phaseEvent).eraseToAnyAsyncSequence(),
                inProgressFilesResult: .success([]))
            let cameraUploadFileDetailsUseCase = MockCameraUploadFileDetailsUseCase(
                fileDetails: [fileEntity]
            )
            let photoLibraryThumbnailUseCase = MockPhotoLibraryThumbnailUseCase()
            let sut = makeSUT(
                cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
                photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            )
            
            await sut.loadInitial()
            await sut.monitorActiveUploads()
            
            #expect(sut.inProgressSnapshotUpdate == .itemAdded(.init(
                fileEntity: fileEntity,
                cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
                thumbnailSize: thumbnailSize)))
        }
        
        @Test("Upload complete should remove from in progress and stop caching")
        func complete() async throws {
            let assetIdentifier = "localIdentifier"
            let phaseEvent = CameraUploadPhaseEventEntity(
                assetIdentifier: assetIdentifier, phase: .completed)
            
            let cameraUploadProgressUseCase = MockCameraUploadProgressUseCase(
                cameraUploadPhaseEventUpdates: SingleItemAsyncSequence(
                    item: phaseEvent).eraseToAnyAsyncSequence(),
                inProgressFilesResult: .success([.init(localIdentifier: assetIdentifier)]))
            let photoLibraryThumbnailUseCase = MockPhotoLibraryThumbnailUseCase()
            let sut = makeSUT(
                cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase
            )
            
            await sut.loadInitial()
            
            await sut.monitorActiveUploads()
            
            #expect(sut.inProgressSnapshotUpdate == .itemRemoved(assetIdentifier))
            
            #expect(photoLibraryThumbnailUseCase.invocations == [
                .startCaching(identifiers: [assetIdentifier], targetSize: thumbnailSize),
                .stopCaching(identifiers: [assetIdentifier], targetSize: thumbnailSize)])
        }
    }
    
    @MainActor
    private static func makeSUT(
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol = MockCameraUploadProgressUseCase(),
        cameraUploadFileDetailsUseCase: some CameraUploadFileDetailsUseCaseProtocol = MockCameraUploadFileDetailsUseCase(),
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol = MockPhotoLibraryThumbnailUseCase()
    ) -> CameraUploadProgressTableViewModel {
        .init(
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            cameraUploadFileDetailsUseCase: cameraUploadFileDetailsUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase)
    }
}
