/// How a folder download ended, counted in files rather than in transfers.
///
/// A folder is a single transfer to its caller but many transfers underneath, and it can finish with an
/// error while most of its files did arrive. Anything that wants to tell the user what happened needs the
/// counts, not just the outcome.
public struct FolderDownloadResultEntity: Sendable, Equatable {
    /// Whether the folder transfer itself finished without error. `false` covers everything from a
    /// single file failing to nothing at all being downloadable.
    public let isSuccess: Bool
    /// How many files the folder was found to contain. `0` only when nothing could be counted at all,
    /// which is the one case where the counts say nothing about what went wrong.
    public let fileCount: Int
    /// How many of those files finished successfully.
    public let downloadedFileCount: Int

    public init(isSuccess: Bool, fileCount: Int, downloadedFileCount: Int) {
        self.isSuccess = isSuccess
        self.fileCount = fileCount
        self.downloadedFileCount = downloadedFileCount
    }
}
