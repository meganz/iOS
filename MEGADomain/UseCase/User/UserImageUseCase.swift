import Combine
import UIKit
import MEGADomain

protocol UserImageUseCaseProtocol {
    func fetchUserAvatar(withUserHandle handle: UInt64,
                         name: String,
                         completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void)
    @discardableResult
    func clearAvatarCache(forUserHandle handle: HandleEntity) -> Bool
    
    func downloadAvatar(forUserHandle handle: HandleEntity) async throws -> UIImage
    func createAvatar(usingUserHandle handle: HandleEntity, name: String) async throws -> UIImage

    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never>
}

struct UserImageUseCase<T: UserImageRepositoryProtocol, U: UserStoreRepositoryProtocol, V: ThumbnailRepositoryProtocol>: UserImageUseCaseProtocol {
    
    private var userImageRepo: T
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
            let displayName = userStoreRepo.getDisplayName(forUserHandle: handle)
            
            do {
                let image = try createAvatar(usingName: displayName ?? name, handle: handle)
                MEGALogDebug("UserImageUseCase: avatar image for \(base64Handle) at path \(destinationURLPath) success")
                completion(.success(image))
            } catch {
                MEGALogDebug("UserImageUseCase: avatar image creation for \(base64Handle) at path \(destinationURLPath) failed with error \(error)")
                if let error = error as? UserImageLoadErrorEntity {
                    completion(.failure(error))
                } else {
                    completion(.failure(.generic))
                }
            }
        }

        MEGALogDebug("UserImageUseCase: load image for \(base64Handle) at path \(destinationURLPath) started")
        userImageRepo.loadUserImage(withUserHandle: base64Handle,
                                    destinationPath: destinationURLPath,
                                    completion: completion)
    }
    
    @discardableResult func clearAvatarCache(forUserHandle handle: HandleEntity) -> Bool {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle) else {
            MEGALogDebug("UserImageUseCase: base64 handle not found for handle \(handle)")
            return false
        }
        
        let destinationURLPath = thumbnailRepo.cachedThumbnailURL(for: base64Handle, type: .thumbnail).path
        if FileManager.default.fileExists(atPath: destinationURLPath) {
            do {
                try FileManager.default.removeItem(atPath: destinationURLPath)
                return true
            } catch {
                MEGALogDebug("UserImageUseCase: Unable to delete the avatar image")
                return false
            }
        }
        
        MEGALogDebug("UserImageUseCase: File does not exists at destination path")
        return false
    }
    
    func downloadAvatar(forUserHandle handle: HandleEntity) async throws -> UIImage {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle) else {
            MEGALogDebug("UserImageUseCase: base64 handle not found for handle \(handle)")
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        let destinationURLPath = thumbnailRepo.cachedThumbnailURL(for: base64Handle, type: .thumbnail).path
        MEGALogDebug("UserImageUseCase: load image for \(base64Handle) at path \(destinationURLPath) started")
        return try await userImageRepo.avatar(forUserHandle: base64Handle, destinationPath: destinationURLPath)

    }
    
    func createAvatar(usingUserHandle handle: HandleEntity, name: String) async throws -> UIImage {
        let displayName = await userStoreRepo.displayName(forUserHandle: handle)
        return try await createAvatarImage(usingName: displayName ?? name, handle: handle)
    }
    
    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never> {
        userImageRepo.requestAvatarChangeNotification(forUserHandles: handles)
    }
    
    @MainActor
    private func createAvatarImage(usingName name: String, handle: HandleEntity) throws -> UIImage {
        try createAvatar(usingName: name, handle: handle)
    }
    
    private func createAvatar(
        usingName name: String,
        handle: HandleEntity,
        size: CGSize = CGSize(width: 100.0, height: 100.0)
    ) throws -> UIImage {
        guard let base64Handle = MEGASdk.base64Handle(forUserHandle: handle),
              let avatarBackgroundColor = MEGASdk.avatarColor(forBase64UserHandle: base64Handle) else {
            throw UserImageLoadErrorEntity.base64EncodingError
        }
        
        let destinationURL = thumbnailRepo.cachedThumbnailURL(for: base64Handle, type: .thumbnail)
        if let image = fetchImage(fromPath: destinationURL.path) {
            return image
        }
        
        let initials = (name as NSString).mnz_initialForAvatar()
        
        let image = UIImage(forName: initials,
                            size: size,
                            backgroundColor: UIColor.mnz_(fromHexString: avatarBackgroundColor),
                            textColor: .white,
                            font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0))
        
        if let imageData = image?.jpegData(compressionQuality: 1.0) {
            try imageData.write(to: destinationURL, options: .atomic)
        }
        
        if let image = image {
            return image
        }

        throw UserImageLoadErrorEntity.unableToCreateImage
    }
    
    private func fetchImage(fromPath path: String) -> UIImage? {
        if FileManager.default.fileExists(atPath: path),
           let image = UIImage(contentsOfFile: path) {
                return image
        }
        
        return nil
    }
}
