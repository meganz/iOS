import MEGADomain
import Foundation

public final class MockUserAlbumRepository: UserAlbumRepositoryProtocol {
    var node: NodeEntity?
    
    init(node: NodeEntity) {
        self.node = node
    }
    
    public static var newRepo: MockUserAlbumRepository {
        MockUserAlbumRepository(node: NodeEntity(handle: 1))
    }
    
    public func albums() async -> [SetEntity] {
        []
    }
    
    public func albumContent(by id: HandleEntity) async -> [SetElementEntity] {
        []
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
        AlbumElementsResultEntity(success: 1, failure: 0)
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
