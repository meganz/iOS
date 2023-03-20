import Foundation
import Combine
import MEGADomain

public struct MockAlbumListUseCase: AlbumListUseCaseProtocol {
    private let cameraUploadNode: NodeEntity?
    private let albums: [AlbumEntity]
    private let createdUserAlbums: [String: AlbumEntity]
    public var albumsUpdatedPublisher: AnyPublisher<Void, Never>
    
    public static func sampleUserAlbum(name: String) -> AlbumEntity {
        AlbumEntity(id: 4, name: name, coverNode: NodeEntity(handle: 4), count: 0, type: .user)
    }
    
    public init(cameraUploadNode: NodeEntity? = nil,
                albums: [AlbumEntity] = [],
                createdUserAlbums: [String: AlbumEntity] = [:],
                albumsUpdatedPublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()) {
        self.cameraUploadNode = cameraUploadNode
        self.albums = albums
        self.createdUserAlbums = createdUserAlbums
        self.albumsUpdatedPublisher = albumsUpdatedPublisher
    }
    
    public func loadCameraUploadNode() async throws -> NodeEntity? {
        cameraUploadNode
    }
    
    public func systemAlbums() async throws -> [AlbumEntity] {
        albums.filter { $0.type != .user }
    }
    
    public func userAlbums() async -> [AlbumEntity] {
        albums.filter { $0.type == .user }
    }
    
    public func createUserAlbum(with name: String?) async throws -> AlbumEntity {
        createdUserAlbums[name ?? ""] ?? MockAlbumListUseCase.sampleUserAlbum(name: name ?? "Custom Name")
    }
    
    public func hasNoPhotosAndVideos() async -> Bool {
        false
    }
    
    public func delete(albums ids: [HandleEntity]) async -> [HandleEntity] {
        albums.map { $0.id }
    }
}
