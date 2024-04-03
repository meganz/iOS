import MEGADomain
import MEGASdk

public actor UserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol {
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func videoPlaylists() async -> [SetEntity] {
        sdk.megaSets().toSetEntities()
            .filter { $0.setType == .playlist }
    }
    
    public func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistElementsResultEntity {
        VideoPlaylistElementsResultEntity(success: 0, failure: 0)
    }
}
