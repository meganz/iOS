public enum ThumbnailErrorEntity: Error, Equatable {
    case noThumbnail(ThumbnailTypeEntity)
    case noThumbnails
    case nodeNotFound
    case previewIsAlreadyLoaded
}
