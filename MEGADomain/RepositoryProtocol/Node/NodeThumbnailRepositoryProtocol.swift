protocol NodeThumbnailRepositoryProtocol {
    func getThumbnailFilePath(base64Handle: String) -> String
    func isThumbnailDownloaded(thumbnailFilePath: String) -> Bool
    func getThumbnail(destinationFilePath: String, completion: @escaping (Result<String, GetThumbnailErrorEntity>) -> Void)
    func iconImagesDictionary() -> [String : String]
}
