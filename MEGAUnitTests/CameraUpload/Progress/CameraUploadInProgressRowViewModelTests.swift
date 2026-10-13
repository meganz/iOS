import Combine
import Foundation
@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
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
        #expect(sut.fileProgress == makeProgressString(progress: uploadProgress))
    }
    
    @MainActor
    @Test("Ensure progress only update with meaningful updates", .timeLimit(.minutes(1)))
    func progressUpdates() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: CameraUploadProgressEntity.self)
        
        let updatedProgress = CameraUploadProgressEntity(
            percentage: 0.90,
            totalBytes: 23456,
            bytesPerSecond: 67890)
        let expectedPercentages = [uploadProgress,
                                   updatedProgress]
        let expectedInfo = [makeProgressString(progress: uploadProgress),
                            makeProgressString(progress: updatedProgress)]
        let expectations = Array(zip(expectedPercentages, expectedInfo))
        
        let sut = Self.makeSUT(
            cameraUploadProgressUseCase: MockCameraUploadProgressUseCase(
                uploadProgressUpdates: stream.eraseToAnyAsyncSequence()
            ))
        
        try await confirmation(expectedCount: expectations.count) { confirmation in
            var expectations = expectations
            let (shownValues, shownValuesContinuation) = AsyncStream.makeStream(of: Void.self)
            var shownValuesIterator = shownValues.makeAsyncIterator()

            let cancellable = Publishers.Zip3(
                sut.$percentage,
                sut.$fileProgress,
                sut.$uploadSpeed)
                .dropFirst()
                .sink { (percentage, fileProgress, uploadSpeed) in
                    let (expectedProgress, expectedProgressInfo) = expectations.removeFirst()
                    #expect(percentage.isApproximatelyEqual(to: expectedProgress.percentage, tolerance: 0.01))
                    #expect(fileProgress == expectedProgressInfo)
                    #expect(uploadSpeed == Strings.Localizable.CameraUploads.Progress.Row.uploadSpeed(String.memoryStyleString(fromByteCount: Int64(expectedProgress.bytesPerSecond))))
                    confirmation()
                    shownValuesContinuation.yield()
                }
            
            let monitor = Task {
                await sut.monitorUploadProgress()
            }

            // Wait until each value is shown before the next yield.
            // Otherwise a busy main actor lets the debounce merge two values into one.
            continuation.yield(uploadProgress)
            await shownValuesIterator.next()
            continuation.yield(uploadProgress)
            // Sleep past the debounce, so the duplicate filter sees the duplicate on its own
            try await Task.sleep(for: .milliseconds(200))
            continuation.yield(updatedProgress)
            await shownValuesIterator.next()
            continuation.finish()

            await monitor.value
            cancellable.cancel()
        }
    }
    
    @MainActor
    private static func makeSUT(
        fileEntity: CameraUploadFileDetailsEntity = .init(localIdentifier: "localId"),
        cameraUploadProgressUseCase: some CameraUploadProgressUseCaseProtocol = MockCameraUploadProgressUseCase(),
        photoLibraryThumbnailProvider: some PhotoLibraryThumbnailProviderProtocol = MockPhotoLibraryThumbnailProvider(),
        thumbnailSize: CGSize = .init(width: 32, height: 32),
        progressUpdateDebounceDuration: Duration = .milliseconds(50)
    ) -> CameraUploadInProgressRowViewModel {
        .init(
            fileEntity: fileEntity,
            cameraUploadProgressUseCase: cameraUploadProgressUseCase,
            photoLibraryThumbnailProvider: photoLibraryThumbnailProvider,
            thumbnailSize: thumbnailSize,
            progressUpdateDebounceDuration: progressUpdateDebounceDuration)
    }
    
    private func makeProgressString(progress: CameraUploadProgressEntity) -> String {
        Strings.Localizable.CameraUploads.Progress.Row.fileProgress(
            String(format: "%.0f%%", progress.percentage * 100),
            String.memoryStyleString(fromByteCount: progress.totalBytes))
    }
}
