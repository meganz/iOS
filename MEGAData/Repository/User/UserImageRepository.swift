import Combine
import MEGADomain

struct UserImageRepository: UserImageRepositoryProtocol {
   
    private let sdk: MEGASdk
    private var userAvatarChangeSubscriber: UserAvatarChangeSubscriber?

    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
  
    func loadUserImage(withUserHandle handle: String?,
                       destinationPath: String,
                       completion: @escaping (Result<UIImage, UserImageLoadErrorEntity>) -> Void) {
        
        let thumbnailRequestDelegate = MEGAGetThumbnailRequestDelegate { request in
            if let filePath = request.file, let image = UIImage(contentsOfFile: filePath) {
                completion(.success(image))
            } else {
                completion(.failure(.unableToFetch))
            }
        }
        
        sdk.getAvatarUser(withEmailOrHandle: handle,
                          destinationFilePath: destinationPath,
                          delegate: thumbnailRequestDelegate)
    }
    
    func avatar(forUserHandle handle: String?, destinationPath: String) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let thumbnailRequestDelegate = AvatarRequestDelegate { request in
                if let filePath = request.file, let image = UIImage(contentsOfFile: filePath) {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: UserImageLoadErrorEntity.unableToFetch)
                }
            }
            
            sdk.getAvatarUser(withEmailOrHandle: handle,
                              destinationFilePath: destinationPath,
                              delegate: thumbnailRequestDelegate)
        }
    }
    
    func avatarColorHex(forBase64UserHandle handle: Base64HandleEntity) -> String? {
        MEGASdk.avatarColor(forBase64UserHandle: handle)
    }
    
    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never> {
        let userAvatarChangeSubscriber = UserAvatarChangeSubscriber(sdk: sdk, handles: handles)
        self.userAvatarChangeSubscriber = userAvatarChangeSubscriber
        return userAvatarChangeSubscriber.monitor
    }
}

fileprivate final class AvatarRequestDelegate: NSObject, MEGARequestDelegate {
    private let completion: (MEGARequest) -> Void
    
    init(completion: @escaping (MEGARequest) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        completion(request)
    }
}

fileprivate final class UserAvatarChangeSubscriber: NSObject, MEGAGlobalDelegate {
    private let handles: [HandleEntity]
    private let source: PassthroughSubject<[HandleEntity], Never>

    var monitor: AnyPublisher<[HandleEntity], Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGASdk, handles: [HandleEntity]) {
        self.handles = handles
        self.source = PassthroughSubject<[HandleEntity], Never>()
        
        super.init()
        
        sdk.add(self, queueType: .globalBackground)
    }
    
    func onUsersUpdate(_ api: MEGASdk, userList: MEGAUserList) {
        guard let userListSize = userList.size else { return }
        let users = (0..<userListSize.intValue)
            .compactMap(userList.user)
            .filter {
                $0.isOwnChange == 0 &&
                $0.hasChangedType(.avatar)
                && handles.contains($0.handle)
            }
        
        if users.isNotEmpty {
            source.send(users.map(\.handle))
        }
    }
}
