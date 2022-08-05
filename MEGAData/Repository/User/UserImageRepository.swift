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
        try await withThrowingTaskGroup(of: UIImage.self) { group in
            group.addTask {
                try userAvatar(forUserHandle: handle, destinationPath: destinationPath)
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: 20_000_000_000)
                try Task.checkCancellation()
                throw UserImageLoadErrorEntity.timeout
            }
            
            let avatar = try await group.next()
            group.cancelAll()
            
            if let avatar = avatar {
                return avatar
            }
            
            throw UserImageLoadErrorEntity.unableToFetch
        }
    }
    
    mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never> {
        let userAvatarChangeSubscriber = UserAvatarChangeSubscriber(sdk: sdk, handles: handles)
        self.userAvatarChangeSubscriber = userAvatarChangeSubscriber
        return userAvatarChangeSubscriber.monitor
    }
    
    private func userAvatar(forUserHandle handle: String?, destinationPath: String) throws -> UIImage {
        let group = DispatchGroup()
        var result: Result<UIImage, UserImageLoadErrorEntity>?
        
        group.enter()
        let thumbnailRequestDelegate = MEGAGetThumbnailRequestDelegate { request in
            if let filePath = request.file, let image = UIImage(contentsOfFile: filePath) {
                result = .success(image)
            } else {
                result = .failure(UserImageLoadErrorEntity.unableToFetch)
            }
            
            group.leave()
        }
        
        sdk.getAvatarUser(withEmailOrHandle: handle,
                          destinationFilePath: destinationPath,
                          delegate: thumbnailRequestDelegate)
        
        group.wait()
        if let result = result {
            switch result {
            case.success(let image):
                return image
            case .failure(let error):
                throw error
            }
        }
        
        throw UserImageLoadErrorEntity.unableToFetch
    }
}

fileprivate final class UserAvatarChangeSubscriber {
    private class UserUpdateListener: NSObject, MEGAGlobalDelegate {
        private let sdk: MEGASdk
        private let handles: [HandleEntity]
        private let source: PassthroughSubject<[HandleEntity], Never>
        
        var monitor: AnyPublisher<[HandleEntity], Never> {
            source.eraseToAnyPublisher()
        }
        
        init(sdk: MEGASdk, handles: [HandleEntity]) {
            self.sdk = sdk
            self.handles = handles
            source = PassthroughSubject<[HandleEntity], Never>()
            super.init()
        }
        
        func start() {
            sdk.add(self)
        }
        
        func stop() {
            sdk.remove(self)
        }
        
        func onUsersUpdate(_ api: MEGASdk, userList: MEGAUserList) {
            let users = (0..<userList.size.intValue)
                .compactMap(userList.user)
                .filter {
                    $0.isOwnChange == 0 &&
                    $0.hasChangedType(.avatar)
                    && handles.contains($0.handle)
                }
            
            if users.isEmpty == false {
                source.send(users.map(\.handle))
            }
        }
    }
    
    private let userUpdateListener: UserUpdateListener

    var monitor: AnyPublisher<[HandleEntity], Never> {
        userUpdateListener.monitor
    }
    
    init(sdk: MEGASdk, handles: [HandleEntity]) {
        userUpdateListener = UserUpdateListener(sdk: sdk, handles: handles)
        userUpdateListener.start()
    }
    
    deinit {
        userUpdateListener.stop()
    }
}
