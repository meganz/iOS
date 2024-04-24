import MEGADomain
import MEGASdk

public struct UserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol {
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    // MARK: - videoPlaylists
    
    public func videoPlaylists() async -> [SetEntity] {
        sdk.megaSets().toSetEntities()
            .filter { $0.setType == .playlist }
    }
    
    // MARK: - addVideosToVideoPlaylist
    
    public func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        guard !nodes.isEmpty else {
            throw VideoPlaylistErrorEntity.invalidOperation
        }
        
        return try await withThrowingTaskGroup(of: (HandleEntity, Result<SetEntity, Error>).self, body: { group in
            for node in nodes {
                group.addTask {
                    try await createSetElement(videoPlaylistId: id, nodeId: node.id)
                }
            }
            
            return try await group.reduce(into: [HandleEntity: Result<SetEntity, Error>](), { result, next in
                result[next.0] = next.1
            })
        })
    }
    
    private func createSetElement(videoPlaylistId: HandleEntity, nodeId: HandleEntity) async throws -> (HandleEntity, Result<SetEntity, Error>) {
        try await withCheckedThrowingContinuation { continuation in
            sdk.createSetElement(videoPlaylistId, nodeId: nodeId, name: "", delegate: RequestDelegate { request, error in
                guard !Task.isCancelled else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                let result = AddVideosToVideoPlaylistResultMapper.map(request: request, error: error)
                continuation.resume(returning: (nodeId, result))
            })
        }
    }
    
    // MARK: - deleteVideoPlaylistElements
    
    public func deleteVideoPlaylistElements(videoPlaylistId: HandleEntity, elementIds: [HandleEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        guard !elementIds.isEmpty else {
            throw VideoPlaylistErrorEntity.invalidOperation
        }
        
        return try await withThrowingTaskGroup(of: (HandleEntity, Result<SetEntity, Error>).self, body: { group in
            for eid in elementIds {
                group.addTask {
                    try await self.removeSetElement(videoPlaylistId: videoPlaylistId, elementId: eid)
                }
            }
            
            return try await group.reduce(into: [HandleEntity: Result<SetEntity, Error>](), { result, next in
                result[next.0] = next.1
            })
        })
    }
    
    private func removeSetElement(videoPlaylistId: HandleEntity, elementId: HandleEntity) async throws -> (HandleEntity, Result<SetEntity, Error>) {
        try await withCheckedThrowingContinuation { continuation in
            sdk.removeSetElement(videoPlaylistId, eid: elementId, delegate: RequestDelegate { request, error in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                let result = DeleteVideoPlaylistElementsMapper.map(request: request, error: error)
                continuation.resume(returning: (elementId, result))
            })
        }
    }
}
