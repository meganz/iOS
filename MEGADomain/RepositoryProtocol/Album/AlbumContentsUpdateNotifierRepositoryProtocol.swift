protocol AlbumContentsUpdateNotifierRepositoryProtocol {
    var onAlbumReload: (() -> Void)? { get set }
}
