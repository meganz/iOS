@testable import MEGA

final class MockNodeThumbnailUseCase: NodeThumbnailUseCaseProtocol {
    var thumbnailFilePath: String = ""
    var isThumbnailDownloaded: Bool = false
    
    var getThumbnailResult: (Result<String, GetThumbnailErrorEntity>) = .failure(.generic)
    
    var iconImagesDictionaryVariable = ["":""]
    
    func getThumbnailFilePath(base64Handle: String) -> String {
        thumbnailFilePath
    }

    func isThumbnailDownloaded(thumbnailFilePath: String) -> Bool {
        isThumbnailDownloaded
    }
    
    func getThumbnail(destinationFilePath: String, completion: @escaping (Result<String, GetThumbnailErrorEntity>) -> Void) {
        completion(getThumbnailResult)
    }
    
    func iconImagesDictionary() -> Dictionary<AnyHashable, Any> {
        iconImagesDictionaryVariable
    }
}
