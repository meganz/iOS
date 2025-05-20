import MEGADomain
import MEGASdk
import MEGASwift

public struct UserVideoPlaylistsRepository: UserVideoPlaylistsRepositoryProtocol {
    
    public static var newRepo: UserVideoPlaylistsRepository {
        UserVideoPlaylistsRepository(
            sdk: .sharedSdk,
            setAndElementsUpdatesProvider: SetAndElementUpdatesProvider()
        )
    }
    
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
    
    public func playlistContentUpdated(by id: HandleEntity) -> AnyAsyncSequence<[SetElementEntity]> {
        setElementsUpdatedAsyncSequence
            .compactMap { nodes in
                let filteredResult = nodes.filter { $0.ownerId == id }
                return filteredResult.isNotEmpty ? filteredResult : nil
            }
            .eraseToAnyAsyncSequence()
    }
    
    // MARK: - addVideosToVideoPlaylist
    
    public func addVideosToVideoPlaylist(by id: HandleEntity, nodes: [NodeEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        guard !nodes.isEmpty else {
            throw VideoPlaylistErrorEntity.invalidOperation
        }
        
        return try await withThrowingTaskGroup(of: (HandleEntity, Result<Void, any Error>).self, body: { group in
            for node in nodes {
                group.addTask {
                    await self.createSetElement(videoPlaylistId: id, nodeId: node.id)
                }
            }

            return try await group.reduce(into: [HandleEntity: Result<Void, any Error>](), { result, next in
                result[next.0] = next.1
            })
        })
    }
    
    private func createSetElement(videoPlaylistId: HandleEntity, nodeId: HandleEntity) async -> (HandleEntity, Result<Void, any Error>) {
        await withAsyncValue { continuation in
            sdk.createSetElement(videoPlaylistId, nodeId: nodeId, name: "", delegate: RequestDelegate { request, error in
                let result = AddVideosToVideoPlaylistResultMapper.map(request: request, error: error)
                continuation(.success((nodeId, result)))
            })
        }
    }
    
    // MARK: - deleteVideoPlaylistElements
    
    public func deleteVideoPlaylistElements(videoPlaylistId: HandleEntity, elementIds: [HandleEntity]) async throws -> VideoPlaylistCreateSetElementsResultEntity {
        guard !elementIds.isEmpty else {
            throw VideoPlaylistErrorEntity.invalidOperation
        }
        
        return try await withThrowingTaskGroup(of: (HandleEntity, Result<Void, any Error>).self, body: { group in
            for eid in elementIds {
                group.addTask {
                    try await self.removeSetElement(videoPlaylistId: videoPlaylistId, elementId: eid)
                }
            }
            
            return try await group.reduce(into: [HandleEntity: Result<Void, any Error>](), { result, next in
                result[next.0] = next.1
            })
        })
    }
    
    private func removeSetElement(videoPlaylistId: HandleEntity, elementId: HandleEntity) async throws -> (HandleEntity, Result<Void, any Error>) {
        try await withAsyncThrowingValue { continuation in
            sdk.removeSetElement(videoPlaylistId, eid: elementId, delegate: RequestDelegate { request, error in
                let result = DeleteVideoPlaylistElementsMapper.map(request: request, error: error)
                continuation(.success((elementId, result)))
            })
        }
    }
    
    // MARK: - deleteVideoPlaylist
    
    public func deleteVideoPlaylist(by videoPlaylist: VideoPlaylistEntity) async throws -> VideoPlaylistEntity {
        try await withAsyncThrowingValue { continuation in
            sdk.removeSet(videoPlaylist.id, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    continuation(.success(videoPlaylist))
                case .failure:
                    continuation(.failure(GenericErrorEntity()))
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
        try await withAsyncThrowingValue { continuation in
            sdk.createSet(name, type: .playlist, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    guard let set = request.set else {
                        continuation(.failure(VideoPlaylistErrorEntity.failedToRetrieveNewlyCreatedPlaylist))
                        return
                    }
                    
                    continuation(.success(set.toSetEntity()))
                case .failure(let error):
                    continuation(.failure(VideoPlaylistErrorEntity.failedToCreatePlaylist(name: name)))
                    log(error: error)
                }
            })
        }
    }
    
    // MARK: - updateVideoPlaylistName
    
    public func updateVideoPlaylistName(_ newName: String, for videoPlaylist: VideoPlaylistEntity) async throws {
        try await withAsyncThrowingValue { continuation in
            sdk.updateSetName(videoPlaylist.id, name: newName, delegate: RequestDelegate { result in
                switch result {
                case .success:
                    continuation(.success(()))
                case .failure:
                    continuation(.failure(VideoPlaylistErrorEntity.failedToUpdateVideoPlaylistName(name: newName)))
                }
            })
        }
    }
    
    // MARK: - Helpers
    
    private func log(error: any Error, file: String = #file, _ line: Int = #line) {
        MEGASdk.log(with: .error, message: "[iOS] \(error.localizedDescription)", filename: file, line: line)
    }
}
