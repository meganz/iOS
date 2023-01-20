import MEGADomain
import Foundation

public struct MockUserAlbumRepository: UserAlbumRepositoryProtocol {
    private let node: NodeEntity?
    private let albums: [SetEntity]
    private let albumContent: [HandleEntity: [SetElementEntity]]
    
    public init(node: NodeEntity? = nil,
                albums: [SetEntity] = [],
                albumContent: [HandleEntity: [SetElementEntity]] = [:]
    ) {
        self.node = node
        self.albums = albums
        self.albumContent = albumContent
    }
    
    public static var newRepo: MockUserAlbumRepository {
        MockUserAlbumRepository()
    }
    
    public func albums() async -> [SetEntity] {
        albums
    }
    
    public func albumContent(by id: HandleEntity) async -> [SetElementEntity] {
        albumContent[id] ?? []
    }
    
    public func createAlbum(_ name: String?) async throws -> SetEntity {
        SetEntity(handle: HandleEntity(1), userId: HandleEntity(2), coverId: HandleEntity(3), modificationTime: Date(), name: name ?? "")
    }
    
    public func updateAlbumName(_ name: String, _ id: HandleEntity) async throws -> String {
        ""
    }
    
    public func deleteAlbum(by id: HandleEntity) async throws -> HandleEntity {
        HandleEntity()
    }
    
    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        AlbumElementsResultEntity(success: UInt(nodes.count), failure: 0)
    }
    
    public func updateAlbumElementName(albumId: HandleEntity, elementId: HandleEntity, name: String) async throws -> String {
        ""
    }
    
    public func updateAlbumElementOrder(albumId: HandleEntity, elementId: HandleEntity, order: Int64) async throws -> Int64 {
        0
    }
    
    public func deleteAlbumElements(albumId: HandleEntity, elementIds: [HandleEntity]) async throws -> AlbumElementsResultEntity {
        AlbumElementsResultEntity(success: 1, failure: 0)
    }
    
    public func updateAlbumCover(for albumId: HandleEntity, elementId: HandleEntity) async throws -> HandleEntity {
        HandleEntity(1)
    }
}
