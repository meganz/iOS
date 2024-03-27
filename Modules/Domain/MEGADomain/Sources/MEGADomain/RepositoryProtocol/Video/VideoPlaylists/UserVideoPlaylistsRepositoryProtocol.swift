public protocol UserVideoPlaylistsRepositoryProtocol: Sendable {
    func videoPlaylists() async throws -> [SetEntity]
}
