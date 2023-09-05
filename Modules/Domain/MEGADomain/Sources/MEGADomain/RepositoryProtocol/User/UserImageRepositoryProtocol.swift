import Combine

public typealias ImageFilePathEntity = String

public protocol UserImageRepositoryProtocol: RepositoryProtocol {
    func loadUserImage(withUserHandle handle: String?,
                       destinationPath: String,
                       completion: @escaping (Result<ImageFilePathEntity, UserImageLoadErrorEntity>) -> Void)
    func avatar(forUserHandle handle: String?, destinationPath: String) async throws -> ImageFilePathEntity
    func avatarColorHex(forBase64UserHandle handle: Base64HandleEntity) -> String?
    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never>
}
