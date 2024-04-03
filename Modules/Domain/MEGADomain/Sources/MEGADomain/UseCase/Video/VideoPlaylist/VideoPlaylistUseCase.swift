import Foundation
import MEGASwift

public protocol VideoPlaylistUseCaseProtocol {
    
    /// Getting MEGA default system video playlists. For example, the favourite playlist.
    /// - Returns: returns array of system video playlists based on requirement.
    func systemVideoPlaylists() async throws -> [VideoPlaylistEntity]
    
    /// Getting MEGA user's video playlists, a user generated video playlist one.
    /// - Returns: returns array of user's created video playlists, returns empty if user has not created video playlist yet.
    func userVideoPlaylists() async -> [VideoPlaylistEntity]
    
}

public struct VideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    private let userVideoPlaylistsRepository: any UserVideoPlaylistsRepositoryProtocol
    
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
            .map { $0.toVideoPlaylistEntity(type: .user) }
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
}
