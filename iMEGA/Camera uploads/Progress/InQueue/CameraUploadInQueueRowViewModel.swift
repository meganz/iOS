import MEGADomain

@MainActor
final class CameraUploadInQueueRowViewModel: ObservableObject {
    private let assetUploadEntity: CameraAssetUploadEntity
    private let photoLibraryThumbnailUseCase: any PhotoLibraryThumbnailUseCaseProtocol
    
    let thumbnailViewModel: CameraUploadThumbnailViewModel
    
    nonisolated init(
        assetUploadEntity: CameraAssetUploadEntity,
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol,
        thumbnailSize: CGSize,
    ) {
        self.assetUploadEntity = assetUploadEntity
        self.photoLibraryThumbnailUseCase = photoLibraryThumbnailUseCase
        thumbnailViewModel = CameraUploadThumbnailViewModel(
            assetIdentifier: assetUploadEntity.localIdentifier,
            thumbnailSize: thumbnailSize,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase)
    }
}

extension CameraUploadInQueueRowViewModel: Identifiable {
    nonisolated var id: String { assetUploadEntity.localIdentifier }
}

extension CameraUploadInQueueRowViewModel: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(assetUploadEntity.localIdentifier)
    }
    
    nonisolated static func == (lhs: CameraUploadInQueueRowViewModel, rhs: CameraUploadInQueueRowViewModel) -> Bool {
        lhs.id == rhs.id
    }
}
