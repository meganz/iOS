@testable import MEGA
import Combine

struct MockUserImageUseCase: UserImageUseCaseProtocol {
    var result: Result<UIImage, UserImageLoadErrorEntity> = .failure(.generic)
    var clearAvatarCacheCompletion: ((MEGAHandle) -> Void)?
    var downloadAvatarCompletion: ((MEGAHandle) -> Void)?
    var createAvatarCompletion: ((MEGAHandle) -> Void)?
    var clearAvatarCache = false
    var avatarChangePublisher = PassthroughSubject<[MEGAHandle], Never>()
    
    func fetchUserAvatar(withUserHandle handle: UInt64, name: String, completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void) {
        completion(result)
    }
    
    @discardableResult
    func clearAvatarCache(forUserHandle handle: MEGAHandle) -> Bool {
        clearAvatarCacheCompletion?(handle)
        return clearAvatarCache
    }
    
    func downloadAvatar(forUserHandle handle: MEGAHandle) async throws -> UIImage {
        downloadAvatarCompletion?(handle)
        switch result {
        case .success(let image):
            return image
        case .failure(let error):
            throw error
        }
    }
    
    func createAvatar(usingUserHandle handle: MEGAHandle, name: String) async throws -> UIImage {
        createAvatarCompletion?(handle)
        switch result {
        case .success(let image):
            return image
        case .failure(let error):
            throw error
        }
    }

    mutating func requestAvatarChangeNotification(forUserHandles handles: [MEGAHandle]) -> AnyPublisher<[MEGAHandle], Never> {
        avatarChangePublisher.eraseToAnyPublisher()
    }
}
