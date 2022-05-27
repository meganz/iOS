
protocol UserImageUseCaseProtocol {
    func fetchUserAvatar(withUserHandle handle: UInt64,
                         name: String,
                         completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void)
}

struct UserImageUseCase<T: UserImageRepositoryProtocol, U: UserStoreRepositoryProtocol, V: ThumbnailRepositoryProtocol>: UserImageUseCaseProtocol {
    
    private let userImageRepo: T
    private let userStoreRepo: U
    private let thumbnailRepo: V
    
    init(userImageRepo: T,
         userStoreRepo: U,
         thumbnailRepo: V) {
        self.userImageRepo = userImageRepo
        self.userStoreRepo = userStoreRepo
        self.thumbnailRepo = thumbnailRepo
    }
    
    func fetchUserAvatar(withUserHandle handle: UInt64,
                         name: String,
                         completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void) {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle) else {
            MEGALogDebug("UserImageUseCase: base64 handle not found for handle \(handle)")
            completion(.failure(.base64EncodingError))
            return
        }
        
        let destinationURLPath = thumbnailRepo.cachedThumbnailURL(for: base64Handle, type: .thumbnail).path
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
    
    private func getAvatarImage(withUserHandle handle: UInt64, name: String, size: CGSize = CGSize(width: 100.0, height: 100.0)) -> UIImage? {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle),
              let avatarBackgroundColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            return nil
        }
        
        let destinationURL = thumbnailRepo.cachedThumbnailURL(for: base64Handle, type: .thumbnail)
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
                            size: size,
                            backgroundColor: UIColor.mnz_(fromHexString: avatarBackgroundColor),
                            textColor: .white,
                            font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0))
        
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
