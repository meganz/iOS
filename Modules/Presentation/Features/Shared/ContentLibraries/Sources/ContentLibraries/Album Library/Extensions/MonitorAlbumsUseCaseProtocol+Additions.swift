import AsyncAlgorithms
import Foundation
import MEGADomain
import MEGASwift

public extension MonitorAlbumsUseCaseProtocol {
    /// Monitor system albums (Favourite, Raw and Gif) yielding updates
    ///
    /// The system albums will return with localized names
    /// - Parameters:
    ///   - excludeSensitives: A boolean value indicating whether to exclude sensitive photos from album covers. They will always be included in count.
    ///   - searchText: string to search albums.
    /// - Returns: An asynchronous sequence of results, where each result contains an array of `AlbumEntity` objects or an error.
    func monitorLocalizedSystemAlbums(
        excludeSensitives: Bool,
        searchText: String? = nil
    ) async -> AnyAsyncSequence<Result<[AlbumEntity], any Error>> {
        await monitorSystemAlbums(excludeSensitives: excludeSensitives)
            .map { systemAlbumResult in
                systemAlbumResult.map { albums in
                    albums.compactMap { album in
                        var album = album
                        if let localizedName = album.type.localizedAlbumName {
                            album.name = localizedName
                        }
                        return if let searchText, !album.name.lowercased().contains(searchText.lowercased()) {
                            nil
                        } else {
                            album
                        }
                    }
                }
            }
            .eraseToAnyAsyncSequence()
    }
    
    /// Monitor user created albums yielding updates
    ///
    /// The async sequence will immediately return user albums then updates when set updates occur.
    /// - Parameters:
    ///   - excludeSensitives: A boolean value indicating whether to exclude sensitive covers from albums.
    ///   - searchText: string to search albums.
    /// - Returns: An asynchronous sequence of `[AlbumEntity]`.
    func monitorSortedUserAlbums(
        excludeSensitives: Bool,
        by areInIncreasingOrder: @escaping @Sendable (AlbumEntity, AlbumEntity) -> Bool,
        searchText: String? = nil
    ) async -> AnyAsyncSequence<[AlbumEntity]> {
        await monitorUserAlbums(excludeSensitives: excludeSensitives)
            .map { userAlbums in
                var sortedUserAlbums = if let searchText {
                    userAlbums.filter { $0.name.lowercased().contains(searchText.lowercased()) }
                } else {
                    userAlbums
                }
                sortedUserAlbums.sort(by: areInIncreasingOrder)
                return sortedUserAlbums
            }
            .eraseToAnyAsyncSequence()
    }
    
    /// Monitor all (localized system and user) albums yielding updates
    ///
    /// The async sequence will immediately yield `[Albums]` then updates if any. If any errors are returned on system albums it will return empty to allow user albums to return
    /// - Parameters:
    ///   - excludeSensitives: A boolean value indicating whether to exclude sensitive covers from albums.
    ///   - searchText: string to search albums.
    /// - Returns: An asynchronous sequence of `[AlbumEntity]`.
    /// - Throws: `CancellationError` if cancelled.
    func monitorAlbums(
        excludeSensitives: Bool,
        searchText: String? = nil
    ) async throws -> AnyAsyncSequence<[AlbumEntity]> {
        let systemAlbumsSequence = await monitorLocalizedSystemAlbums(
            excludeSensitives: excludeSensitives,
            searchText: searchText
        ).map {
            ((try? $0.get()) ?? [])
        }
        
        try Task.checkCancellation()
        
        let userAlbumsSequence = await monitorSortedUserAlbums(
            excludeSensitives: excludeSensitives,
            by: { $0.creationTime ?? Date.distantPast > $1.creationTime ?? Date.distantPast },
            searchText: searchText)
        
        try Task.checkCancellation()
        
        return combineLatest(systemAlbumsSequence, userAlbumsSequence)
            .map {
                $0 + $1
            }.eraseToAnyAsyncSequence()
    }
}
