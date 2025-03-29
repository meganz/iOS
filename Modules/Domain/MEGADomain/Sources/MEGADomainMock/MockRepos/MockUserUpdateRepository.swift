import MEGADomain
import MEGASwift

public final class MockUserUpdateRepository: UserUpdateRepositoryProtocol {
    public static var newRepo: MockUserUpdateRepository {
        MockUserUpdateRepository()
    }

    public let usersUpdates: AnyAsyncSequence<[UserEntity]>
    
    public init(usersUpdates: AnyAsyncSequence<[UserEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self.usersUpdates = usersUpdates
    }
}
