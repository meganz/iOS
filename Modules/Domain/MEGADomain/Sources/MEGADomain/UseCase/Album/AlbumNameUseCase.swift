import Foundation

public protocol AlbumNameUseCaseProtocol: Sendable {
    func userAlbumNames() async -> [String]
}

public struct AlbumNameUseCase<T: UserAlbumRepositoryProtocol>: AlbumNameUseCaseProtocol {
    private let userAlbumRepository: T
    
    public init(userAlbumRepository: T) {
        self.userAlbumRepository = userAlbumRepository
    }
    
    public func userAlbumNames() async -> [String] {
        await userAlbumRepository.albums().map(\.name)
    }
}
