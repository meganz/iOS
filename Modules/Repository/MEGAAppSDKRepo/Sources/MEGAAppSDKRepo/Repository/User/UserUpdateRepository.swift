import MEGADomain
import MEGASwift

public struct UserUpdateRepository: UserUpdateRepositoryProtocol {
    public static var newRepo: UserUpdateRepository {
        return UserUpdateRepository()
    }
    
    public var usersUpdates: AnyAsyncSequence<[UserEntity]> {
        MEGAUpdateHandlerManager.shared.userUpdates
    }
}
