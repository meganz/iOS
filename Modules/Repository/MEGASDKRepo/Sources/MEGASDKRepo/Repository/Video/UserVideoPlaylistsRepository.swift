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
    
    public func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        guard nodes.isNotEmpty else {
            throw VideoPlaylistErrorEntity.invalidOperation
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var finalResult: [HandleEntity: Result<SetEntity, any Error>] = [:]
            for node in nodes {
                sdk.createSetElement(id, nodeId: node.id, name: "", delegate: RequestDelegate { request, error in
                    guard Task.isCancelled == false else {
                        continuation.resume(throwing: CancellationError())
                        return
                    }
                    finalResult[node.id] = AddVideosToVideoPlaylistResultMapper.map(request: request, error: error)
                })
            }
            continuation.resume(returning: finalResult)
        }
    }
}
