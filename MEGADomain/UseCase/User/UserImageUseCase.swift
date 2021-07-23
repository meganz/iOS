
protocol UserImageUseCaseProtocol {
    func fetchUserAvatar(withUserHandle handle: UInt64,
                         name: String,
                         completion: @escaping (Result<UIImage, UserImageLoadError>) -> Void)
}

struct UserImageUseCase: UserImageUseCaseProtocol {
    private struct Constants {
        static let avatarDefaultSize = CGSize(width: 100.0, height: 100.0)
    }
    
    private let userImageRepo: UserImageRepositoryProtocol
    private let userStoreRepo: UserStoreRepositoryProtocol
    private let appGroupFilePathUseCase: MEGAAppGroupFilePathUseCaseProtocol
    
    init(userImageRepo: UserImageRepositoryProtocol,
         userStoreRepo: UserStoreRepositoryProtocol,
         appGroupFilePathUseCase: MEGAAppGroupFilePathUseCaseProtocol) {
        self.userImageRepo = userImageRepo
        self.userStoreRepo = userStoreRepo
        self.appGroupFilePathUseCase = appGroupFilePathUseCase
    }
    
    func fetchUserAvatar(withUserHandle handle: UInt64,
                         name: String,
                         completion: @escaping (Result<UIImage, UserImageLoadError>) -> Void) {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle) else {
            completion(.failure(.base64EncodingError))
            return
        }
        
        let destinationURLPath = appGroupFilePathUseCase.cachedThumbnailImageURL(forNode: base64Handle).path
        if let image = fetchImage(fromPath: destinationURLPath) {
            completion(.success(image))
        } else {
            if let image = getAvatarImage(withUserHandle: handle, name: name) {
                completion(.success(image))
            }
        }

        userImageRepo.loadUserImage(withUserHandle: base64Handle,
                                    destinationPath: destinationURLPath,
                                    completion: completion)
    }
    
    private func getAvatarImage(withUserHandle handle: UInt64, name: String) -> UIImage? {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle),
              let avatarBackgroundColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            return nil
        }
        
        let destinationURL = appGroupFilePathUseCase.cachedThumbnailImageURL(forNode: base64Handle)
        if let image = fetchImage(fromPath: destinationURL.path) {
            return image
        }
        
        let initials: String
        if let dispalyName = userStoreRepo.getDisplayName(forUserHandle: handle) {
            initials = (dispalyName as NSString).mnz_initialForAvatar()
        } else {
            initials = (name as NSString).mnz_initialForAvatar()
        }
        
        let image = UIImage(forName: initials,
                            size: Constants.avatarDefaultSize,
                            backgroundColor: UIColor.mnz_(fromHexString: avatarBackgroundColor),
                            textColor: .white,
                            font: UIFont.systemFont(ofSize: Constants.avatarDefaultSize.width/2.0))
        
        if let imageData = image?.jpegData(compressionQuality: 1.0) {
            try? imageData.write(to: destinationURL, options: .atomic)
        }

        return image
    }
    
    private func fetchImage(fromPath path: String) -> UIImage? {
        if FileManager.default.fileExists(atPath: path),
           let image = UIImage(contentsOfFile: path) {
                return image
        }
        
        return nil
    }
}
