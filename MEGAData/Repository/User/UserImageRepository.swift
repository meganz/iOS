
struct UserImageRepository: UserImageRepositoryProtocol {
   
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
  
    func loadUserImage(withUserHandle handle: String?,
                       destinationPath: String,
                       completion: @escaping (Result<UIImage, UserImageLoadError>) -> Void) {
        
        let thumbnailRequestDelegate = MEGAGetThumbnailRequestDelegate { request in
            if let filePath = request.file, let image = UIImage(contentsOfFile: filePath) {
                completion(.success(image))
            } else {
                completion(.failure(.unableToFetch))
            }
        }
        
        sdk.getAvatarUser(withEmailOrHandle: handle,
                          destinationFilePath: destinationPath,
                          delegate: thumbnailRequestDelegate)
    }
}
