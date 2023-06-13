import Foundation
import MEGADomain

protocol MEGAAvatarUseCaseProtocol {

    func loadRemoteAvatarImage(completion: @escaping (UIImage?) -> Void)

    func getCachedAvatarImage() -> UIImage?

    func loadCachedAvatarImage(completion: @escaping (UIImage?) -> Void)
}

final class MEGAavatarUseCase: MEGAAvatarUseCaseProtocol {

    private let avatarRepository: SDKAvatarClient
    private let avatarFileSystemClient: FileSystemImageCacheClient
    private let accountUseCase: any AccountUseCaseProtocol
    private let thumbnailRepo: any ThumbnailRepositoryProtocol
    private let handleUseCase: any MEGAHandleUseCaseProtocol
    
    init(
        megaAvatarClient: SDKAvatarClient,
        avatarFileSystemClient: FileSystemImageCacheClient,
        accountUseCase: any AccountUseCaseProtocol,
        thumbnailRepo: any ThumbnailRepositoryProtocol,
        handleUseCase: any MEGAHandleUseCaseProtocol
    ) {
        self.avatarRepository = megaAvatarClient
        self.avatarFileSystemClient = avatarFileSystemClient
        self.accountUseCase = accountUseCase
        self.thumbnailRepo = thumbnailRepo
        self.handleUseCase = handleUseCase
    }

    // MARK: - Shared Avatar Caching Path

    private func cachedAvatarFilePath(of userBase64Handle: Base64HandleEntity) -> URL {
        thumbnailRepo.generateCachingURL(for: userBase64Handle, type: .thumbnail)
    }

    // MARK: - Search Local Cached Avatar

    func getCachedAvatarImage() -> UIImage? {
        guard let handle = accountUseCase.currentUserHandle else {
            return nil
        }
        
        guard let userBase64Handle = handleUseCase.base64Handle(forUserHandle: handle) else {
            return nil
        }

        let localAvatarCachingPath = cachedAvatarFilePath(of: userBase64Handle)
        return avatarFileSystemClient.cachedImage(localAvatarCachingPath).flatMap(UIImage.init(data:))
    }

    func loadCachedAvatarImage(completion: @escaping (UIImage?) -> Void) {
        guard let handle = accountUseCase.currentUserHandle else {
            completion(nil)
            return
        }
        
        guard let userBase64Handle = handleUseCase.base64Handle(forUserHandle: handle) else {
            completion(nil)
            return
        }

        let localAvatarCachingPath = cachedAvatarFilePath(of: userBase64Handle)
        avatarFileSystemClient.loadCachedImageAsync(localAvatarCachingPath) { imageData in
            completion(imageData.flatMap(UIImage.init(data:)))
        }
    }

    func loadRemoteAvatarImage(completion: @escaping (UIImage?) -> Void) {
        guard let handle = accountUseCase.currentUserHandle else {
            completion(nil)
            return
        }
        
        guard let userBase64Handle = handleUseCase.base64Handle(forUserHandle: handle) else {
            completion(nil)
            return
        }

        let localAvatarCachingPath = cachedAvatarFilePath(of: userBase64Handle)
        avatarRepository.loadUserAvatar(handle, localAvatarCachingPath, completion)
    }
}
