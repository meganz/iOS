import CoreGraphics
import Foundation
@testable import Transfer

extension TransferStatusSnapshot {
    static func fixture(
        progress: CGFloat = 0.5,
        hasError: Bool = false,
        hasOverquota: Bool = false,
        isPaused: Bool = false,
        isCompleted: Bool = false,
        activeUploadCount: Int = 1,
        activeDownloadCount: Int = 0,
        completedFileCount: Int = 1,
        totalFileCount: Int = 2,
        speedBytesPerSecond: Int64 = 1024
    ) -> TransferStatusSnapshot {
        TransferStatusSnapshot(
            progress: progress,
            hasError: hasError,
            hasOverquota: hasOverquota,
            isPaused: isPaused,
            isCompleted: isCompleted,
            activeUploadCount: activeUploadCount,
            activeDownloadCount: activeDownloadCount,
            completedFileCount: completedFileCount,
            totalFileCount: totalFileCount,
            speedBytesPerSecond: speedBytesPerSecond
        )
    }
}

@available(iOS 16.2, *)
extension TransferLiveActivityAttributes.ContentState {
    static func fixture(
        progressFraction: Double = 0.5,
        state: TransferLiveActivityState = .active,
        direction: TransferLiveActivityDirection? = .uploading,
        statusText: String = "Uploading files",
        percentageText: String = "50%",
        fileCountText: String = "1 of 2",
        formattedSpeed: String = "1 KB/s"
    ) -> TransferLiveActivityAttributes.ContentState {
        TransferLiveActivityAttributes.ContentState(
            progressFraction: progressFraction,
            state: state,
            direction: direction,
            statusText: statusText,
            percentageText: percentageText,
            fileCountText: fileCountText,
            formattedSpeed: formattedSpeed
        )
    }
}
