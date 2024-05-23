import MEGADomain
import MEGASdk
import MEGASwift

public struct UserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol {
    
    public var setsUpdatedAsyncSequence: AnyAsyncSequence<[SetEntity]> {
        setAndElementsUpdatesProvider.setUpdates(filteredBy: [.playlist])
    }
    
    public var setElementsUpdatedAsyncSequence: AnyAsyncSequence<[SetElementEntity]> {
        setAndElementsUpdatesProvider.setElementUpdates()
    }
    
    private let sdk: MEGASdk
    private let setAndElementsUpdatesProvider: any SetAndElementUpdatesProviderProtocol
    
    public init(
        sdk: MEGASdk,
        setAndElementsUpdatesProvider: some SetAndElementUpdatesProviderProtocol
    ) {
        self.sdk = sdk
        self.setAndElementsUpdatesProvider = setAndElementsUpdatesProvider
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
                    try await self.createSetElement(videoPlaylistId: id, nodeId: node.id)
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
    
    // MARK: - deleteVideoPlaylist
    
    public func deleteVideoPlaylist(by videoPlaylist: VideoPlaylistEntity) async throws -> VideoPlaylistEntity {
        try await withCheckedThrowingContinuation { continuation in
            sdk.removeSet(videoPlaylist.id, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                
                switch result {
                case .success:
                    continuation.resume(returning: videoPlaylist)
                case .failure:
                    continuation.resume(throwing: GenericErrorEntity())
                }
            })
        }
    }
    
    // MARK: - videoPlaylistContent
    
    public func videoPlaylistContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity] {
        sdk.megaSetElements(bySid: id, includeElementsInRubbishBin: includeElementsInRubbishBin)
            .toSetElementsEntities()
    }
    
    // MARK: - createVideoPlaylist
    
    public func createVideoPlaylist(_ name: String?) async throws -> SetEntity {
        return try await withCheckedThrowingContinuation { continuation in
            sdk.createSet(name, type: .playlist, delegate: RequestDelegate { result in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    log(error: CancellationError())
                    return
                }
                
                switch result {
                case .success(let request):
                    guard let set = request.set else {
                        continuation.resume(throwing: VideoPlaylistErrorEntity.failedToRetrieveNewlyCreatedPlaylist)
                        return
                    }
                    
                    continuation.resume(returning: set.toSetEntity())
                case .failure(let error):
                    continuation.resume(throwing: VideoPlaylistErrorEntity.failedToCreatePlaylist(name: name))
                    log(error: error)
                }
            })
        }
    }
    
    private func log(error: Error, file: String = #file, _ line: Int = #line) {
        MEGASdk.log(with: .error, message: "[iOS] \(error.localizedDescription)", filename: file, line: line)
    }
}
