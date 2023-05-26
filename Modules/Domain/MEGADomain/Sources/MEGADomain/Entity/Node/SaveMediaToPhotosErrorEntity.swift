
public enum SaveMediaToPhotosErrorEntity: Error {
    case imageNotSaved
    case videoNotSaved
    case wrongExtensionFormat
    case downloadFailed
    case fileDownloadInProgress
    case nodeNotFound
    case cancelled
}
