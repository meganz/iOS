import MEGASwift

public protocol UserUpdateRepositoryProtocol: RepositoryProtocol, Sendable {
    var usersUpdates: AnyAsyncSequence<[UserEntity]> { get }
}
