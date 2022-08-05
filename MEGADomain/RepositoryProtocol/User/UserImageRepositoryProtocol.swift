import Combine
import MEGADomain

protocol UserImageRepositoryProtocol {
    func loadUserImage(withUserHandle handle: String?,
                       destinationPath: String,
                       completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void)
    func avatar(forUserHandle handle: String?, destinationPath: String) async throws -> UIImage
    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never>
}
