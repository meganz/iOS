// MARK: - Use case protocol -
protocol NodeThumbnailUseCaseProtocol {
    func getThumbnailFilePath(base64Handle: MEGABase64Handle) -> String
    func isThumbnailDownloaded(thumbnailFilePath: String) -> Bool
    func getThumbnail(destinationFilePath: String, completion: @escaping (Result<String, GetThumbnailErrorEntity>) -> Void)
    func iconImagesDictionary() -> Dictionary<AnyHashable, Any>
}

struct NodeThumbnailUseCase: NodeThumbnailUseCaseProtocol {
    private let repository: NodeThumbnailRepositoryProtocol
    
    init(repository: NodeThumbnailRepositoryProtocol) {
        self.repository = repository
    }
    
    func getThumbnailFilePath(base64Handle: MEGABase64Handle) -> String {
        repository.getThumbnailFilePath(base64Handle: base64Handle)
    }
    
    func isThumbnailDownloaded(thumbnailFilePath: String) -> Bool {
        repository.isThumbnailDownloaded(thumbnailFilePath: thumbnailFilePath)
    }
    
    func getThumbnail(destinationFilePath: String, completion: @escaping (Result<String, GetThumbnailErrorEntity>) -> Void) {
        repository.getThumbnail(destinationFilePath: destinationFilePath, completion: completion)
    }
    
    func iconImagesDictionary() -> Dictionary<AnyHashable, Any> {
        repository.iconImagesDictionary()
    }
}

