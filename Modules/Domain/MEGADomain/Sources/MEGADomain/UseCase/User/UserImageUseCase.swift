import Combine

public protocol UserImageUseCaseProtocol: Sendable {
    /// Returns the hexadecimal color code for the avatar of a user identified by the given Base64 handle.
    /// - Parameter handle: The Base64 handle of the user.
    /// - Returns: The hexadecimal color code of the user's avatar, or nil if the handle is invalid. Example: "#FF6A19"
    func avatarColorHex(forBase64UserHandle handle: Base64HandleEntity) -> String?
    
    /// Clears the avatar cache for the specified base64 handle.
    /// - Parameter base64Handle: The base64 handle of the user.
    func clearAvatarCache(base64Handle: Base64HandleEntity)
    
    /// Fetches the avatar image for a given base64 handle.
    /// - Parameters:
    ///   - base64Handle: The base64 handle of the user.
    ///   - forceDownload: A flag indicating whether to force download the image even if it is already cached.
    /// - Returns: The file path of the fetched image.
    /// - Throws: An error if the image fetching fails.
    func fetchAvatar(base64Handle: Base64HandleEntity, forceDownload: Bool) async throws -> ImageFilePathEntity
    
    /// Requests a notification for avatar change for the specified user handles.
    /// - Parameter handles: An array of `HandleEntity` objects representing the user handles.
    /// - Returns: A publisher that emits an array of `HandleEntity` objects when the avatar change notification is received.
    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never>
}

public struct UserImageUseCase<T: UserImageRepositoryProtocol, U: UserStoreRepositoryProtocol, V: ThumbnailRepositoryProtocol, W: FileSystemRepositoryProtocol>: UserImageUseCaseProtocol {
    
    private var userImageRepo: T
    private let userStoreRepo: U
    private let thumbnailRepo: V
    private let fileSystemRepo: W
    
    public init(userImageRepo: T,
                userStoreRepo: U,
                thumbnailRepo: V,
                fileSystemRepo: W) {
        self.userImageRepo = userImageRepo
        self.userStoreRepo = userStoreRepo
        self.thumbnailRepo = thumbnailRepo
        self.fileSystemRepo = fileSystemRepo
    }
    
    public func avatarColorHex(forBase64UserHandle handle: Base64HandleEntity) -> String? {
        userImageRepo.avatarColorHex(forBase64UserHandle: handle)
    }
    
    public func clearAvatarCache(base64Handle: Base64HandleEntity) {
        let destinationURL = thumbnailRepo.generateCachingURL(for: base64Handle, type: .thumbnail)
        guard fileSystemRepo.fileExists(at: destinationURL) else { return }
        try? fileSystemRepo.removeItem(at: destinationURL)
    }
    
    public func fetchAvatar(base64Handle: Base64HandleEntity, forceDownload: Bool = false) async throws -> ImageFilePathEntity {
        let destinationURL = thumbnailRepo.generateCachingURL(for: base64Handle, type: .thumbnail)
        let destinationURLPath = destinationURL.path
        if fileSystemRepo.fileExists(at: destinationURL), !forceDownload {
            return destinationURLPath
        } else {
            let imageFilePath = try await userImageRepo.avatar(forUserHandle: base64Handle, destinationPath: destinationURLPath)
            return imageFilePath
        }
    }
    
    public mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never> {
        userImageRepo.requestAvatarChangeNotification(forUserHandles: handles)
    }
}
