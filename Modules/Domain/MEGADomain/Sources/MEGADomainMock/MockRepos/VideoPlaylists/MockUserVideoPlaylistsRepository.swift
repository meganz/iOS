import MEGADomain

public actor MockUserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol {
    
    public enum Message : Sendable {
        case userVideoPlaylists
    }
    
    public private(set) var messages = [Message]()
    
    private let result: Result<[SetEntity], Error>
    
    public init(videoPlaylistsResult: Result<[SetEntity], Error>) {
        self.result = videoPlaylistsResult
    }
    
    public func videoPlaylists() async throws -> [SetEntity] {
        messages.append(.userVideoPlaylists)
        return try result.get()
    }
}
