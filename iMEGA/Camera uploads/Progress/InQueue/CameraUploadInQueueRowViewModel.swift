import MEGAAppPresentation
import MEGADomain

@MainActor
final class CameraUploadInQueueRowViewModel: ObservableObject {
    @Published private(set) var fileName = ""
    
    private let assetUploadEntity: CameraAssetUploadEntity
    private let cameraUploadFileDetailsUseCase: any CameraUploadFileDetailsUseCaseProtocol
    
    let thumbnailViewModel: CameraUploadThumbnailViewModel
    
    nonisolated init(
        assetUploadEntity: CameraAssetUploadEntity,
        cameraUploadFileDetailsUseCase: some CameraUploadFileDetailsUseCaseProtocol,
        photoLibraryThumbnailProvider: some PhotoLibraryThumbnailProviderProtocol,
        thumbnailSize: CGSize,
    ) {
        self.assetUploadEntity = assetUploadEntity
        self.cameraUploadFileDetailsUseCase = cameraUploadFileDetailsUseCase
        thumbnailViewModel = CameraUploadThumbnailViewModel(
            assetIdentifier: assetUploadEntity.localIdentifier,
            thumbnailSize: thumbnailSize,
            photoLibraryThumbnailProvider: photoLibraryThumbnailProvider)
    }
    
    func loadName() {
        do {
            fileName = try cameraUploadFileDetailsUseCase.uploadFileName(for: assetUploadEntity)
        } catch {
            MEGALogError("[\(type(of: self))] failed to retrieve upload file name: \(error.localizedDescription)")
        }
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
