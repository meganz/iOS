@testable import MEGA
import Combine
import MEGADomain

struct MockUserImageUseCase: UserImageUseCaseProtocol {
    var result: Result<UIImage, UserImageLoadErrorEntity> = .failure(.generic)
    var clearAvatarCacheCompletion: ((HandleEntity) -> Void)?
    var downloadAvatarCompletion: ((HandleEntity) -> Void)?
    var createAvatarCompletion: ((HandleEntity) -> Void)?
    var clearAvatarCache = false
    var avatarChangePublisher = PassthroughSubject<[HandleEntity], Never>()
    
    func fetchUserAvatar(withUserHandle handle: HandleEntity,
                         base64Handle: Base64HandleEntity,
                         avatarBackgroundHexColor: String,
                         name: String,
                         completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void) {
        completion(result)
    }
    
    func clearAvatarCache(withUserHandle handle: HandleEntity, base64Handle: Base64HandleEntity) {
        clearAvatarCacheCompletion?(handle)
    }
    
    func downloadAvatar(withUserHandle handle: HandleEntity, base64Handle: Base64HandleEntity) async throws -> UIImage {
        downloadAvatarCompletion?(handle)
        switch result {
        case .success(let image):
            return image
        case .failure(let error):
            throw error
        }
    }
    
    func createAvatar(withUserHandle handle: HandleEntity,
                      base64Handle: Base64HandleEntity,
                      avatarBackgroundHexColor: String,
                      name: String) async throws -> UIImage {
        createAvatarCompletion?(handle)
        switch result {
        case .success(let image):
            return image
        case .failure(let error):
            throw error
        }
    }

    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never> {
        avatarChangePublisher.eraseToAnyPublisher()
    }
}
