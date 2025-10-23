import MEGADomain
import MEGARepo

@MainActor
final class CameraUploadProgressTableViewModel: ObservableObject {
    enum InProgressSnapshotUpdate: Equatable {
        case initialLoad([CameraUploadInProgressRowViewModel])
        case itemAdded(CameraUploadInProgressRowViewModel)
        case itemRemoved(CameraUploadLocalIdentifierEntity)
    }
    // MARK: - Published Properties
    @Published private(set) var inProgressSnapshotUpdate: InProgressSnapshotUpdate?
    
    // MARK: - Private Properties
    private let cameraUploadProgressUseCase: any CameraUploadProgressUseCaseProtocol
    private let cameraUploadFileDetailsUseCase: any CameraUploadFileDetailsUseCaseProtocol
    private let photoLibraryThumbnailUseCase: any PhotoLibraryThumbnailUseCaseProtocol
    private let thumbnailSize: CGSize = .init(width: 32, height: 32)
    
    // MARK: - Internal Properties
    let rowHeight: CGFloat = 60
    
    init(
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol,
        cameraUploadFileDetailsUseCase: some CameraUploadFileDetailsUseCaseProtocol,
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol
    ) {
        self.cameraUploadProgressUseCase = cameraUploadProgressUseCase
        self.cameraUploadFileDetailsUseCase = cameraUploadFileDetailsUseCase
        self.photoLibraryThumbnailUseCase = photoLibraryThumbnailUseCase
    }
    
    deinit {
        photoLibraryThumbnailUseCase.clearCache()
    }
    
    func loadInitial() async {
        do {
            let inProgressVMs = try await cameraUploadProgressUseCase.inProgressFiles()
                .map {
                    CameraUploadInProgressRowViewModel(
                        fileEntity: $0,
                        cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                        photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
                        thumbnailSize: thumbnailSize)
                }
            if inProgressVMs.isNotEmpty {
                photoLibraryThumbnailUseCase.startCaching(
                    for: inProgressVMs.map(\.id), targetSize: thumbnailSize)
            }
            
            try Task.checkCancellation()
            
            inProgressSnapshotUpdate = .initialLoad(inProgressVMs)
        } catch {
            MEGALogError("[\(type(of: self))] initial load failed error: \(error)")
        }
    }
    
    func monitorActiveUploads() async {
        for await phaseEvent in await cameraUploadProgressUseCase.cameraUploadPhaseEventUpdates {
            guard !Task.isCancelled else { break }
            
            switch phaseEvent.phase {
            case .uploading:
                guard let fileEntity = try? await cameraUploadFileDetailsUseCase.fileDetails(
                    for: phaseEvent.assetIdentifier) else {
                    continue
                }
                inProgressSnapshotUpdate = .itemAdded(.init(
                    fileEntity: fileEntity,
                    cameraUploadProgressUseCase: cameraUploadProgressUseCase,
                    photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
                    thumbnailSize: thumbnailSize))
            case .completed:
                inProgressSnapshotUpdate = .itemRemoved(phaseEvent.assetIdentifier)
                
                photoLibraryThumbnailUseCase.stopCaching(
                    for: [phaseEvent.assetIdentifier], targetSize: thumbnailSize)
            default: continue
            }
        }
    }
}
