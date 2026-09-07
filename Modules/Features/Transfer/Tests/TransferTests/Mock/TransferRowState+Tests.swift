@testable import Transfer

extension TransferRowState {
    init(
        direction: Direction = .download,
        status: Status = .queued,
        progress: Double = 0,
        transferredBytes: Int64 = 0,
        totalBytes: Int64 = 0,
        speed: Int64 = 0
    ) {
        self.init(
            id: 0,
            fileName: "file.txt",
            direction: direction,
            status: status,
            progress: progress,
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
            speed: speed,
            finishDate: nil,
            errorDescription: nil,
            location: nil,
            canViewInFolder: true,
            isRetryable: false
        )
    }
}
