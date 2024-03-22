import Foundation
import MEGASwift

public protocol VideoPlaylistUseCaseProtocol {
    
    /// Getting MEGA default system video playlists. For example, the favourite playlist.
    /// - Returns: returns array of system video playlists based on requirement.
    func systemVideoPlaylists() async throws -> [VideoPlaylistEntity]
}

public struct VideoPlaylistUseCase: VideoPlaylistUseCaseProtocol {
    
    private let fileSearchUseCase: any FilesSearchUseCaseProtocol
    
    public init(
        fileSearchUseCase: some FilesSearchUseCaseProtocol
    ) {
        self.fileSearchUseCase = fileSearchUseCase
    }
    
    public func systemVideoPlaylists() async throws -> [VideoPlaylistEntity] {
        let favoriteVideos = try await videos().filter(\.isFavourite)
        return [ createFavouriteSystemPlyalist(videos: favoriteVideos) ]
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
            coverNode: nil,
            count: videos.count,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date(),
            sharedLinkStatus: .exported(false)
        )
    }
}
