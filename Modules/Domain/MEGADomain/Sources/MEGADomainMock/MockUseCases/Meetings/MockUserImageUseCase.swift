@preconcurrency import Combine
import MEGADomain

public struct MockUserImageUseCase: UserImageUseCaseProtocol {
    private let fetchAvatarResult: Result<ImageFilePathEntity, UserImageLoadErrorEntity>
    private let clearAvatarCacheCompletion: (@Sendable (Base64HandleEntity) -> Void)?
    private let downloadAvatarCompletion: (@Sendable (Base64HandleEntity) -> Void)?
    public let avatarChangePublisher: PassthroughSubject<[HandleEntity], Never>
    
    public init(fetchAvatarResult: Result<ImageFilePathEntity, UserImageLoadErrorEntity> = .failure(.generic),
                clearAvatarCacheCompletion: (@Sendable (Base64HandleEntity) -> Void)? = nil,
                downloadAvatarCompletion: (@Sendable (Base64HandleEntity) -> Void)? = nil,
                avatarChangePublisher: PassthroughSubject<[HandleEntity], Never> = PassthroughSubject<[HandleEntity], Never>()
    ) {
        self.fetchAvatarResult = fetchAvatarResult
        self.clearAvatarCacheCompletion = clearAvatarCacheCompletion
        self.downloadAvatarCompletion = downloadAvatarCompletion
        self.avatarChangePublisher = avatarChangePublisher
    }
    
    public func avatarColorHex(forBase64UserHandle handle: Base64HandleEntity) -> String? {
        ""
    }
    
    public func clearAvatarCache(base64Handle: Base64HandleEntity) {
        clearAvatarCacheCompletion?(base64Handle)
    }
    
    public func fetchAvatar(base64Handle: Base64HandleEntity, forceDownload: Bool) async throws -> ImageFilePathEntity {
        downloadAvatarCompletion?(base64Handle)
        switch fetchAvatarResult {
        case .success(let imageFilePath):
            return imageFilePath
        case .failure(let error):
            throw error
        }
    }
    
    mutating public func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never> {
        avatarChangePublisher.eraseToAnyPublisher()
    }
}
