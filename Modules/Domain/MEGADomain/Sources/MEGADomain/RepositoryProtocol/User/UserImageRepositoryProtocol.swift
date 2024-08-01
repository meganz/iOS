import Combine

public typealias ImageFilePathEntity = String

public protocol UserImageRepositoryProtocol: RepositoryProtocol, Sendable {
    func avatar(forUserHandle handle: String?, destinationPath: String) async throws -> ImageFilePathEntity
    func avatarColorHex(forBase64UserHandle handle: Base64HandleEntity) -> String?
    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never>
}
