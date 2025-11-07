import MEGADomain
import MEGAL10n
import MEGASwift

@MainActor
final class CameraUploadInProgressRowViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var fileName = ""
    @Published private(set) var fileProgress = ""
    @Published private(set) var uploadSpeed = ""
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
        updateFileInfo(uploadProgress)
    }
    
    func monitorUploadProgress() async {
        for await progress in await cameraUploadProgressUseCase.uploadProgressUpdates(
            for: fileEntity.localIdentifier).debounce(for: progressUpdateDebounceDuration)
            .removeDuplicates(by: { !$0.isMeaningfullyDifferent(from: $1) }) {
            guard !Task.isCancelled else { break }
            updateFileInfo(progress)
        }
    }
    
    private func updateFileInfo(_ progress: CameraUploadProgressEntity) {
        percentage = progress.percentage
        fileProgress = progress.fileProgress
        uploadSpeed = progress.uploadSpeed
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
    fileprivate var fileProgress: String {
        Strings.Localizable.CameraUploads.Progress.Row.fileProgress(
            String(format: "%.0f%%", percentage * 100),
            String.memoryStyleString(fromByteCount: totalBytes))
    }
    
    fileprivate var uploadSpeed: String {
        Strings.Localizable.CameraUploads.Progress.Row.uploadSpeed(String.memoryStyleString(fromByteCount: Int64(bytesPerSecond)))
    }
    
    fileprivate func isMeaningfullyDifferent(from other: CameraUploadProgressEntity) -> Bool {
        !percentage.isApproximatelyEqual(to: other.percentage, tolerance: 0.01) ||
        !bytesPerSecond.isApproximatelyEqual(
            to: other.bytesPerSecond,
            tolerance: max(100, 0.05 * max(bytesPerSecond, other.bytesPerSecond)) // Only change if speed changed by 5% or 100B/s minimum
        )
    }
}
