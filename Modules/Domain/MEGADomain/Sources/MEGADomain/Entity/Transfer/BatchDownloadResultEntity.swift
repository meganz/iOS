public enum BatchDownloadResultEntity: Sendable, Equatable {
    case completed(fileCount: Int)
    case partiallyFailed(downloadedFileCount: Int, failedFileCount: Int)
    case failed
}
