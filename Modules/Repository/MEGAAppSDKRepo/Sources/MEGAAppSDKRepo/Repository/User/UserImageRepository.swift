@preconcurrency import Combine
import MEGADomain
import MEGASdk

public struct UserImageRepository: UserImageRepositoryProtocol {
    public static var newRepo: UserImageRepository {
        UserImageRepository(sdk: MEGASdk.sharedSdk)
    }

    private let sdk: MEGASdk
    private var userAvatarChangeSubscriber: UserAvatarChangeSubscriber?

    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }

    public func avatar(forUserHandle handle: String?, destinationPath: String) async throws -> ImageFilePathEntity {
        try await withCheckedThrowingContinuation { continuation in
            let thumbnailRequestDelegate = AvatarRequestDelegate { request in
                if let filePath = request.file {
                    guard Task.isCancelled == false else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    continuation.resume(returning: filePath)
                } else {
                    continuation.resume(throwing: UserImageLoadErrorEntity.unableToFetch)
                }
            }

            sdk.getAvatarUser(withEmailOrHandle: handle,
                              destinationFilePath: destinationPath,
                              delegate: thumbnailRequestDelegate,
                              queueType: .globalBackground)
        }
    }

    public func avatarColorHex(forBase64UserHandle handle: Base64HandleEntity) -> String? {
        MEGASdk.avatarColor(forBase64UserHandle: handle)
    }

   public mutating func requestAvatarChangeNotification(forUserHandles handles: [HandleEntity]) -> AnyPublisher<[HandleEntity], Never> {
        let userAvatarChangeSubscriber = UserAvatarChangeSubscriber(sdk: sdk, handles: handles)
        self.userAvatarChangeSubscriber = userAvatarChangeSubscriber
        return userAvatarChangeSubscriber.monitor
    }
}

private final class AvatarRequestDelegate: NSObject, MEGARequestDelegate {
    private let completion: (MEGARequest) -> Void

    init(completion: @escaping (MEGARequest) -> Void) {
        self.completion = completion
        super.init()
    }

    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        completion(request)
    }
}

private final class UserAvatarChangeSubscriber: NSObject, MEGAGlobalDelegate, Sendable {
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

    func onUsersUpdate(_ api: MEGASdk, userList: MEGAUserList?) {
        guard let userList else { return }
        guard userList.size > 0 else { return }
        let users = (0..<userList.size)
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
