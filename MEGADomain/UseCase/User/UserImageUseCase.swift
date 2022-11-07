import Combine
import UIKit
import MEGADomain
import MEGAUI

protocol UserImageUseCaseProtocol {
    func fetchUserAvatar(withUserHandle handle: HandleEntity,
                         base64Handle: Base64HandleEntity,
                         avatarBackgroundHexColor: String,
                         name: String,
                         completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void)
    func clearAvatarCache(withUserHandle handle: HandleEntity, base64Handle: Base64HandleEntity)
    func downloadAvatar(withUserHandle handle: HandleEntity, base64Handle: Base64HandleEntity) async throws -> UIImage
    func createAvatar(withUserHandle handle: HandleEntity,
                      base64Handle: Base64HandleEntity?,
                      avatarBackgroundHexColor: String,
                      backgroundGradientHexColor: String?,
                      name: String) async throws -> UIImage
    func createAvatar(withUserHandle handle: HandleEntity,
                      base64Handle: Base64HandleEntity?,
                      avatarBackgroundHexColor: String,
                      backgroundGradientHexColor: String?,
                      name: String,
                      isRightToLeftLanguage: Bool,
                      shouldCache: Bool,
                      useCache: Bool) async throws -> UIImage
    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never>
}

struct UserImageUseCase<T: UserImageRepositoryProtocol, U: UserStoreRepositoryProtocol, V: ThumbnailRepositoryProtocol, W: FileSystemRepositoryProtocol>: UserImageUseCaseProtocol {
    
    private var userImageRepo: T
    private let userStoreRepo: U
    private let thumbnailRepo: V
    private let fileSystemRepo: W
    
    init(userImageRepo: T,
         userStoreRepo: U,
         thumbnailRepo: V,
         fileSystemRepo: W) {
        self.userImageRepo = userImageRepo
        self.userStoreRepo = userStoreRepo
        self.thumbnailRepo = thumbnailRepo
        self.fileSystemRepo = fileSystemRepo
    }
    
    func fetchUserAvatar(withUserHandle handle: HandleEntity,
                         base64Handle: Base64HandleEntity,
                         avatarBackgroundHexColor: String,
                         name: String,
                         completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void) {
        
        let destinationURLPath = thumbnailRepo.cachedThumbnailURL(for: base64Handle, type: .thumbnail).path
        if let image = fetchImage(fromPath: destinationURLPath) {
            completion(.success(image))
            return
        } else {
            let displayName = userStoreRepo.getDisplayName(forUserHandle: handle)
            
            do {
                let image = try createAvatar(usingName: displayName ?? name,
                                             base64Handle: base64Handle,
                                             avatarBackgroundHexColor: avatarBackgroundHexColor)
                completion(.success(image))
            } catch {
                if let error = error as? UserImageLoadErrorEntity {
                    completion(.failure(error))
                } else {
                    completion(.failure(.generic))
                }
            }
        }

        userImageRepo.loadUserImage(withUserHandle: base64Handle,
                                    destinationPath: destinationURLPath,
                                    completion: completion)
    }
    
    func clearAvatarCache(withUserHandle handle: HandleEntity,
                          base64Handle: Base64HandleEntity) {
        let destinationURL = thumbnailRepo.cachedThumbnailURL(for: base64Handle, type: .thumbnail)
        guard fileSystemRepo.fileExists(at: destinationURL) else { return }
        fileSystemRepo.removeFile(at: destinationURL)
    }
    
    func downloadAvatar(withUserHandle handle: HandleEntity, base64Handle: Base64HandleEntity) async throws -> UIImage {
        let destinationURLPath = thumbnailRepo.cachedThumbnailURL(for: base64Handle, type: .thumbnail).path
        return try await userImageRepo.avatar(forUserHandle: base64Handle, destinationPath: destinationURLPath)
    }
    
    func createAvatar(withUserHandle handle: HandleEntity,
                      base64Handle: Base64HandleEntity?,
                      avatarBackgroundHexColor: String,
                      backgroundGradientHexColor: String? = nil,
                      name: String) async throws -> UIImage {
        let displayName = await userStoreRepo.displayName(forUserHandle: handle)
        return try await createAvatarImage(usingName: displayName ?? name,
                                           base64Handle: base64Handle,
                                           avatarBackgroundHexColor: avatarBackgroundHexColor,
                                           backgroundGradientHexColor: backgroundGradientHexColor)
    }
    
    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never> {
        userImageRepo.requestAvatarChangeNotification(forUserHandles: handles)
    }
    
    func createAvatar(withUserHandle handle: HandleEntity,
                      base64Handle: Base64HandleEntity?,
                      avatarBackgroundHexColor: String,
                      backgroundGradientHexColor: String?,
                      name: String,
                      isRightToLeftLanguage: Bool,
                      shouldCache: Bool,
                      useCache: Bool) async throws -> UIImage {
        let displayName = await userStoreRepo.displayName(forUserHandle: handle)
        return try createAvatar(usingName: displayName ?? name,
                                base64Handle: base64Handle,
                                avatarBackgroundHexColor: avatarBackgroundHexColor,
                                backgroundGradientHexColor: backgroundGradientHexColor,
                                isRightToLeftLanguage: isRightToLeftLanguage,
                                shouldCache: shouldCache,
                                useCache: useCache)
    }
    
    // MARK: - Private methods
    
    @MainActor
    private func createAvatarImage(usingName name: String,
                                   base64Handle: Base64HandleEntity?,
                                   avatarBackgroundHexColor: String,
                                   backgroundGradientHexColor: String? = nil) async throws -> UIImage {
        try createAvatar(usingName: name,
                         base64Handle: base64Handle,
                         avatarBackgroundHexColor: avatarBackgroundHexColor,
                         backgroundGradientHexColor: backgroundGradientHexColor)
    }
    
    private func createAvatar(
        usingName name: String,
        base64Handle: Base64HandleEntity?,
        avatarBackgroundHexColor: String,
        backgroundGradientHexColor: String? = nil,
        isRightToLeftLanguage: Bool? = nil,
        shouldCache: Bool = true,
        useCache: Bool = true,
        size: CGSize = CGSize(width: 100.0, height: 100.0)
    ) throws -> UIImage {
        if let base64Handle {
            let destinationURL = thumbnailRepo.cachedThumbnailURL(for: base64Handle, type: .thumbnail)
            if let image = fetchImage(fromPath: destinationURL.path) {
                return image
            }
        }
        
        let initials = (name as NSString).mnz_initialForAvatar()
        
        let backgroundGradientColor: UIColor?
        if let backgroundGradientHexColor {
            backgroundGradientColor = UIColor.mnz_(fromHexString: backgroundGradientHexColor)
        } else {
            backgroundGradientColor = nil
        }
        
        let image: UIImage?
        if let isRightToLeftLanguage {
            image = UIImage.drawImage(
                forInitials: initials,
                size: size,
                backgroundColor: UIColor.mnz_(fromHexString: avatarBackgroundHexColor) ?? .black,
                backgroundGradientColor: backgroundGradientColor,
                textColor: .white,
                font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0),
                isRightToLeftLanguage: isRightToLeftLanguage)
        } else {
            image = UIImage(
                forName: initials,
                size: size,
                backgroundColor: UIColor.mnz_(fromHexString: avatarBackgroundHexColor),
                backgroundGradientColor: backgroundGradientColor,
                textColor: .white,
                font: UIFont.systemFont(ofSize: min(size.width, size.height)/2.0)
            )
        }
        
        if let base64Handle, shouldCache {
            let destinationURL = thumbnailRepo.cachedThumbnailURL(for: base64Handle, type: .thumbnail)
            if let imageData = image?.jpegData(compressionQuality: 1.0) {
                try imageData.write(to: destinationURL, options: .atomic)
            }
        }
        
        if let image = image {
            return image
        }

        throw UserImageLoadErrorEntity.unableToCreateImage
    }
    
    private func fetchImage(fromPath path: String) -> UIImage? {
        guard let url = URL(string: path),
              fileSystemRepo.fileExists(at: url),
              let image = UIImage(contentsOfFile: path) else {
            return nil
        }
        return image
    }
}
