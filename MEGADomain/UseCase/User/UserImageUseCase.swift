
protocol UserImageUseCaseProtocol {
    func fetchUserAvatar(withUserHandle handle: UInt64,
                         name: String,
                         completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void)
}

struct UserImageUseCase: UserImageUseCaseProtocol {
    private struct Constants {
        static let avatarDefaultSize = CGSize(width: 100.0, height: 100.0)
    }
    
    private let userImageRepo: UserImageRepositoryProtocol
    private let userStoreRepo: UserStoreRepositoryProtocol
    private let fileRepo: FileRepositoryProtocol
    
    init(userImageRepo: UserImageRepositoryProtocol,
         userStoreRepo: UserStoreRepositoryProtocol,
         fileRepo: FileRepositoryProtocol) {
        self.userImageRepo = userImageRepo
        self.userStoreRepo = userStoreRepo
        self.fileRepo = fileRepo
    }
    
    func fetchUserAvatar(withUserHandle handle: UInt64,
                         name: String,
                         completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void) {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle) else {
            MEGALogDebug("UserImageUseCase: base64 handle not found for handle \(handle)")
            completion(.failure(.base64EncodingError))
            return
        }
        
        let destinationURLPath = fileRepo.cachedThumbnailURL(for: base64Handle).path
        if let image = fetchImage(fromPath: destinationURLPath) {
            MEGALogDebug("UserImageUseCase: imaged fetched for \(base64Handle) at path \(destinationURLPath)")
            completion(.success(image))
            return
        } else {
            MEGALogDebug("UserImageUseCase: avatar image for \(base64Handle) at path \(destinationURLPath) started")
            if let image = getAvatarImage(withUserHandle: handle, name: name) {
                MEGALogDebug("UserImageUseCase: avatar image for \(base64Handle) at path \(destinationURLPath) success")
                completion(.success(image))
            }
        }

        MEGALogDebug("UserImageUseCase: load image for \(base64Handle) at path \(destinationURLPath) started")
        userImageRepo.loadUserImage(withUserHandle: base64Handle,
                                    destinationPath: destinationURLPath,
                                    completion: completion)
    }
    
    private func getAvatarImage(withUserHandle handle: UInt64, name: String) -> UIImage? {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle),
              let avatarBackgroundColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            return nil
        }
        
        let destinationURL = fileRepo.cachedThumbnailURL(for: base64Handle)
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
