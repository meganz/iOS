@testable import MEGA
import Combine

struct MockUserImageUseCase: UserImageUseCaseProtocol {
    var result: Result<UIImage, UserImageLoadErrorEntity> = .failure(.generic)
    var clearAvatarCacheCompletion: ((HandleEntity) -> Void)?
    var downloadAvatarCompletion: ((HandleEntity) -> Void)?
    var createAvatarCompletion: ((HandleEntity) -> Void)?
    var clearAvatarCache = false
    var avatarChangePublisher = PassthroughSubject<[HandleEntity], Never>()
    
    func fetchUserAvatar(withUserHandle handle: UInt64, name: String, completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void) {
        completion(result)
    }
    
    @discardableResult
    func clearAvatarCache(forUserHandle handle: HandleEntity) -> Bool {
        clearAvatarCacheCompletion?(handle)
        return clearAvatarCache
    }
    
    func downloadAvatar(forUserHandle handle: HandleEntity) async throws -> UIImage {
        downloadAvatarCompletion?(handle)
        switch result {
        case .success(let image):
            return image
        case .failure(let error):
            throw error
        }
    }
    
    func createAvatar(usingUserHandle handle: HandleEntity, name: String) async throws -> UIImage {
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
