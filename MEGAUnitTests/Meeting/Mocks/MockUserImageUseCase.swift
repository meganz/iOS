import Combine
@testable import MEGA
import MEGADomain

struct MockUserImageUseCase: UserImageUseCaseProtocol {
    var fetchAvatarResult: Result<ImageFilePathEntity, UserImageLoadErrorEntity> = .failure(.generic)
    var clearAvatarCacheCompletion: ((Base64HandleEntity) -> Void)?
    var downloadAvatarCompletion: ((Base64HandleEntity) -> Void)?
    var avatarChangePublisher = PassthroughSubject<[HandleEntity], Never>()
    
    func avatarColorHex(forBase64UserHandle handle: Base64HandleEntity) -> String? {
        ""
    }
    
    func clearAvatarCache(base64Handle: Base64HandleEntity) {
        clearAvatarCacheCompletion?(base64Handle)
    }
    
    func fetchAvatar(base64Handle: Base64HandleEntity, forceDownload: Bool) async throws -> ImageFilePathEntity {
        downloadAvatarCompletion?(base64Handle)
        switch fetchAvatarResult {
        case .success(let imageFilePath):
            return imageFilePath
        case .failure(let error):
            throw error
        }
    }
    
    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never> {
        avatarChangePublisher.eraseToAnyPublisher()
    }
}
