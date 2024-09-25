import MEGADomain
import MEGASDKRepo
import MEGASwift

public struct MockUserUpdateProvider: UserUpdateProviderProtocol {
    
    public let userUpdates: AnyAsyncSequence<UserEntity>
    
    public init(userUpdates: AnyAsyncSequence<UserEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self.userUpdates = userUpdates
    }
}
