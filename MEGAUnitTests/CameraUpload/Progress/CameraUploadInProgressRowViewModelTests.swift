import Combine
import Foundation
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import Testing

struct CameraUploadInProgressRowViewModelTests {
    private let uploadProgress = CameraUploadProgressEntity(
        percentage: 0.85,
        totalBytes: 12345,
        bytesPerSecond: 56789)
    
    @MainActor
    @Test func initialProgress() async {
        let expectedFileName = "file name.jpg"
        let fileEntity = CameraUploadFileDetailsEntity(
            localIdentifier: "localId",
            fileName: expectedFileName)
        
        let sut = Self.makeSUT(
            fileEntity: fileEntity,
            cameraUploadProgressUseCase: MockCameraUploadProgressUseCase(
                uploadProgress: uploadProgress
            )
        )
        
        await sut.load()
        
        #expect(sut.fileName == expectedFileName)
        #expect(sut.percentage == uploadProgress.percentage)
        #expect(sut.fileProgressInformation == makeProgressString(progress: uploadProgress))
    }
    
    @MainActor
    @Test("Ensure progress only update with meaningful updates")
    func progressUpdates() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: CameraUploadProgressEntity.self)
        
        let updatedProgress = CameraUploadProgressEntity(
            percentage: 0.90,
            totalBytes: 23456,
            bytesPerSecond: 67890)
        let expectedPercentages = [uploadProgress.percentage,
                                   updatedProgress.percentage]
        let expectedInfo = [makeProgressString(progress: uploadProgress),
                            makeProgressString(progress: updatedProgress)]
        let expectations = Array(zip(expectedPercentages, expectedInfo))
        
        let sut = Self.makeSUT(
            cameraUploadProgressUseCase: MockCameraUploadProgressUseCase(
                uploadProgressUpdates: stream.eraseToAnyAsyncSequence()
            ))
        
        try await confirmation(expectedCount: expectations.count) { confirmation in
            let monitor = Task {
                try await withTimeout(seconds: 5) { // Cancel task if stream don't finish
                    await sut.monitorUploadProgress()
                }
            }
            
            var expectations = expectations
            
            let cancellable = sut.$percentage.dropFirst()
                .zip(sut.$fileProgressInformation.dropFirst())
                .sink { (percentage, progressInfo) in
                    let (expectedPercentage, expectedProgressInfo) = expectations.removeFirst()
                    #expect(percentage.isApproximatelyEqual(to: expectedPercentage, tolerance: 0.01))
                    #expect(progressInfo == expectedProgressInfo)
                    confirmation()
                }
               
            continuation.yield(uploadProgress)
            // Sleep to get past the debounce
            try await Task.sleep(nanoseconds: 100_000_000)
            continuation.yield(uploadProgress)
            try await Task.sleep(nanoseconds: 100_000_000)
            continuation.yield(updatedProgress)
            continuation.finish()
            
            try await monitor.value
            cancellable.cancel()
            monitor.cancel()
        }
    }
    
    @MainActor
    private static func makeSUT(
        fileEntity: CameraUploadFileDetailsEntity = .init(localIdentifier: "localId"),
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol = MockCameraUploadProgressUseCase(),
        photoLibraryThumbnailUseCase: some PhotoLibraryThumbnailUseCaseProtocol = MockPhotoLibraryThumbnailUseCase(),
        thumbnailSize: CGSize = .init(width: 32, height: 32),
        progressUpdateDebounceDuration: Duration = .milliseconds(50)
    ) -> CameraUploadInProgressRowViewModel {
        .init(
            fileEntity: fileEntity,
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            photoLibraryThumbnailUseCase: photoLibraryThumbnailUseCase,
            thumbnailSize: thumbnailSize,
            progressUpdateDebounceDuration: progressUpdateDebounceDuration)
    }
    
    private func makeProgressString(progress: CameraUploadProgressEntity) -> String {
        Strings.Localizable.CameraUploads.Progress.Row.uploadProgressFormat(
            String(format: "%.0f%%", progress.percentage * 100),
            String.memoryStyleString(fromByteCount: progress.totalBytes),
            String.memoryStyleString(fromByteCount: Int64(progress.bytesPerSecond)))
    }
}
