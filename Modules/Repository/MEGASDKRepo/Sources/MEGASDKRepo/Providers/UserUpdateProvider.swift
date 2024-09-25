import MEGADomain
import MEGASdk
import MEGASwift

public protocol UserUpdateProviderProtocol: Sendable {
    /// User updates from `MEGAGlobalDelegate` `onUsersUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `UserEntity` on user changes  until sequence terminated
    var userUpdates: AnyAsyncSequence<UserEntity> { get }
}

public extension UserUpdateProviderProtocol {
    
    /// User updates from `MEGAGlobalDelegate` `onUsersUpdate` as an `AnyAsyncSequence`,  this sequence will only push new value when the given change type has matched.
    /// - Parameter changeType: Filters the sequence by the given change type.
    /// - Returns: It will yield `UserEntity` on user changes  until sequence terminated
    func userUpdates(filterBy changeType: UserEntity.ChangeTypeEntity) -> AnyAsyncSequence<UserEntity> {
        userUpdates
            .filter { $0.changes.intersection(changeType).isNotEmpty }
            .eraseToAnyAsyncSequence()
    }
}

public struct UserUpdateProvider: UserUpdateProviderProtocol {
    
    public var userUpdates: AnyAsyncSequence<UserEntity> {
        AsyncStream { continuation in
            let delegate = UserUpdateGlobalDelegate { users in
                guard let currentUser = sdk.myUser?.toUserEntity(),
                      let changedUser = users.first(where: { $0.handle == currentUser.handle }) else {
                    return
                }
                
                continuation.yield(changedUser)
            }
            
            sdk.addMEGAGlobalDelegateAsync(delegate, queueType: .globalBackground)

            continuation.onTermination = { @Sendable _ in
                sdk.removeMEGAGlobalDelegateAsync(delegate)
            }
        }.eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
}

private final class UserUpdateGlobalDelegate: NSObject, MEGAGlobalDelegate, Sendable {
    
    private let onUserUpdate: @Sendable ([UserEntity]) -> Void
    
    init(onUserUpdate: @escaping @Sendable ([UserEntity]) -> Void) {
        self.onUserUpdate = onUserUpdate
    }
    
    func onUsersUpdate(_ api: MEGASdk, userList: MEGAUserList) {
        onUserUpdate(userList.toUserEntities())
    }
}
