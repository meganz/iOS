import MEGADomain

public struct MockAlbumNameUseCase: AlbumNameUseCaseProtocol {
    private let userAlbumNames: [String]
    
    public init(userAlbumNames: [String] = []) {
        self.userAlbumNames = userAlbumNames
    }
    
    public func userAlbumNames() async -> [String] {
        userAlbumNames
    }
}
