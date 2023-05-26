public enum ThumbnailErrorEntity: Error {
    case generic
    case noThumbnail(ThumbnailTypeEntity)
    case noThumbnails
    case nodeNotFound
    case previewIsAlreadyLoaded
}
