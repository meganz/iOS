import AsyncAlgorithms
import Foundation
import MEGASwift

public protocol VideoPlaylistUseCaseProtocol {
    
    /// An AsyncSequence of Void that triggers updates when changes occur in the user's video playlists.
    var videoPlaylistsUpdatedAsyncSequence: AnyAsyncSequence<Void> { get }
    
    /// Getting MEGA default system video playlists. For example, the favourite playlist.
    /// - Returns: returns array of system video playlists based on requirement.
    func systemVideoPlaylists() async throws -> [VideoPlaylistEntity]
    
    /// Getting MEGA user's video playlists, a user generated video playlist one.
    /// - Returns: returns array of user's created video playlists, returns empty if user has not created video playlist yet.
    func userVideoPlaylists() async -> [VideoPlaylistEntity]
    
    /// Create user video playlist with specific name
    /// - Parameter name: Name of the playlist that will be created.
    /// - Returns: `SetEntity` instance representing created video playlist.
    /// - throws: Throw `VideoPlaylistErrorEntity` if it failed during adding videos to playlist or `CancellationError` if cancelled.
    func createVideoPlaylist(_ name: String?) async throws -> VideoPlaylistEntity
    
    /// Rename specific video playlist
    /// - Parameters:
    ///   - newName: new name for the video playlist
    ///   - videoPlaylistEntity: `VideoPlaylistEntity` instance that wants to be renamed
    /// - Returns: return new instance of renamed `VideoPlaylistEntity`
    /// - throws: Throw `VideoPlaylistErrorEntity` if it failed during adding videos to playlist or `CancellationError` if cancelled.
    func updateVideoPlaylistName(_ newName: String, for videoPlaylistEntity: VideoPlaylistEntity) async throws -> VideoPlaylistEntity
}

public struct VideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private let userVideoPlaylistsRepository: any UserVideoPlaylistsRepositoryProtocol
    
    public var videoPlaylistsUpdatedAsyncSequence: AnyAsyncSequence<Void> {
        merge(favoriteVideoPlaylistUpdates, userVideoPlaylistUpdates)
            .eraseToAnyAsyncSequence()
    }
    
    private var favoriteVideoPlaylistUpdates: AnyAsyncSequence<Void> {
        fileSearchUseCase.nodeUpdates
            .filter { $0.contains { node in node.name.fileExtensionGroup.isVideo }}
            .map { _ in () }
            .eraseToAnyAsyncSequence()
    }
    
    private var userVideoPlaylistUpdates: AnyAsyncSequence<Void> {
        let videoPlaylistUpdatesStream = userVideoPlaylistsRepository.setsUpdatedAsyncSequence
            .filter { $0.isNotEmpty && $0.contains { $0.setType == .playlist } }
            .map { _ in () }
            .eraseToAnyAsyncSequence()
        
        let videoPlaylistContentUpdatesStream = userVideoPlaylistsRepository.setElementsUpdatedAsyncSequence
            .filter { $0.isNotEmpty }
            .map { _ in () }
            .eraseToAnyAsyncSequence()
        
        return merge(videoPlaylistUpdatesStream, videoPlaylistContentUpdatesStream)
            .eraseToAnyAsyncSequence()
    }
    
    public init(
        fileSearchUseCase: some FilesSearchUseCaseProtocol,
        userVideoPlaylistsRepository: some UserVideoPlaylistsRepositoryProtocol
    ) {
        self.fileSearchUseCase = fileSearchUseCase
        self.userVideoPlaylistsRepository = userVideoPlaylistsRepository
    }
    
    public func systemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        let favoriteVideos = try await videos().filter(\.isFavourite)
        return [ createFavouriteSystemPlyalist(videos: favoriteVideos) ]
    }
    
    public func userVideoPlaylists() async -> [VideoPlaylistEntity] {
        let playlistSetEntities = await userVideoPlaylistsRepository.videoPlaylists()
        return playlistSetEntities
            .filter { $0.setType == .playlist }
            .map { $0.toVideoPlaylistEntity(type: .user, sharedLinkStatus: .exported($0.isExported)) }
    }
    
    private func videos() async throws -> [NodeEntity] {
        try await withAsyncThrowingValue { result in
            fileSearchUseCase.search(
                string: "",
                parent: nil,
                recursive: true,
                supportCancel: false,
                sortOrderType: .defaultAsc,
                cancelPreviousSearchIfNeeded: true
            ) { videos, isFail in
                guard !isFail else {
                    result(.failure(GenericErrorEntity()))
                    return
                }
                result(.success(videos ?? []))
            }
        }
    }
    
    private func createFavouriteSystemPlyalist(videos: [NodeEntity]) -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            id: 1,
            name: "",
            count: videos.count,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date(),
            sharedLinkStatus: .exported(false)
        )
    }
    
    public func createVideoPlaylist(_ name: String?) async throws -> VideoPlaylistEntity {
        try await userVideoPlaylistsRepository.createVideoPlaylist(name)
            .toVideoPlaylistEntity(type: .user, sharedLinkStatus: .exported(false), count: 0)
    }
    
    public func updateVideoPlaylistName(_ newName: String, for videoPlaylistEntity: VideoPlaylistEntity) async throws -> VideoPlaylistEntity {
        guard videoPlaylistEntity.name != newName else {
            throw VideoPlaylistErrorEntity.invalidOperation
        }
        
        return try await userVideoPlaylistsRepository
            .updateVideoPlaylistName(newName, for: videoPlaylistEntity)
            .toVideoPlaylistEntity(
                type: videoPlaylistEntity.type, 
                sharedLinkStatus: videoPlaylistEntity.sharedLinkStatus,
                count: videoPlaylistEntity.count
            )
    }
}
