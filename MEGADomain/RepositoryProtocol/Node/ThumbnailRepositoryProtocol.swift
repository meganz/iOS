protocol ThumbnailRepositoryProtocol {
    func hasCachedThumbnail(for node: NodeEntity) -> Bool
    func hasCachedPreview(for node: NodeEntity) -> Bool
    func cachedThumbnail(for node: NodeEntity) -> URL
    func cachedPreview(for node: NodeEntity) -> URL
    
    func loadThumbnail(for node: NodeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
    func loadPreview(for node: NodeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
}
