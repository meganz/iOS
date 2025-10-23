import MEGADomain
import MEGAL10n
import MEGASwift

@MainActor
final class CameraUploadInProgressRowViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var fileName = ""
    @Published private(set) var fileProgressInformation = ""
    @Published private(set) var percentage: Double = 0.0
    
    // MARK: - Private Properties
    private let fileEntity: CameraUploadFileDetailsEntity
    private let cameraUploadProgressUseCase: any CameraUploadProgressUseCaseProtocol
    private let progressUpdateDebounceDuration: Duration
    
    // MARK: - Internal Properties
    let thumbnailViewModel: CameraUploadThumbnailViewModel
    
    init(
        fileEntity: CameraUploadFileDetailsEntity,
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol,
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol,
        thumbnailSize: CGSize,
        progressUpdateDebounceDuration: Duration = .milliseconds(300)
    ) {
        self.fileEntity = fileEntity
        self.cameraUploadProgressUseCase = cameraUploadProgressUseCase
        self.progressUpdateDebounceDuration = progressUpdateDebounceDuration
        
        fileName = fileEntity.fileName
        thumbnailViewModel = CameraUploadThumbnailViewModel(
            assetIdentifier: fileEntity.localIdentifier,
            thumbnailSize: thumbnailSize,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            placeholderFileExtension: fileEntity.fileExtension)
    }
    
    func load() async {
        let uploadProgress = await cameraUploadProgressUseCase.uploadProgress(
            for: fileEntity.localIdentifier)
        percentage = uploadProgress.percentage
        fileProgressInformation = uploadProgress.progressInfo
    }
    
    func monitorUploadProgress() async {
        for await progress in await cameraUploadProgressUseCase.uploadProgressUpdates(
            for: fileEntity.localIdentifier).debounce(for: progressUpdateDebounceDuration)
            .removeDuplicates(by: { !$0.isMeaningfullyDifferent(from: $1) }) {
            guard !Task.isCancelled else { break }
            
            percentage = progress.percentage
            fileProgressInformation = progress.progressInfo
        }
    }
}

extension CameraUploadInProgressRowViewModel: Identifiable {
    nonisolated var id: CameraUploadLocalIdentifierEntity {
        fileEntity.localIdentifier
    }
}

extension CameraUploadInProgressRowViewModel: Hashable {
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(fileEntity.localIdentifier)
    }
    
    nonisolated static func == (lhs: CameraUploadInProgressRowViewModel, rhs: CameraUploadInProgressRowViewModel) -> Bool {
        lhs.id == rhs.id
    }
}

extension CameraUploadProgressEntity {
    fileprivate var progressInfo: String {
        Strings.Localizable.CameraUploads.Progress.Row.uploadProgressFormat(
            String(format: "%.0f%%", percentage * 100),
            String.memoryStyleString(fromByteCount: totalBytes),
            String.memoryStyleString(fromByteCount: Int64(bytesPerSecond)))
    }
    
    fileprivate func isMeaningfullyDifferent(from other: CameraUploadProgressEntity) -> Bool {
        !percentage.isApproximatelyEqual(to: other.percentage, tolerance: 0.01) ||
        !bytesPerSecond.isApproximatelyEqual(
            to: other.bytesPerSecond,
            tolerance: max(100, 0.05 * max(bytesPerSecond, other.bytesPerSecond)) // Only change if speed changed by 5% or 100B/s minimum
        )
    }
}
