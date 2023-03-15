import MEGADomain
import Foundation
import Combine

public struct MockUserAlbumRepository: UserAlbumRepositoryProtocol {
    public static var newRepo = MockUserAlbumRepository()
    private let node: NodeEntity?
    private let albums: [SetEntity]
    private let albumContent: [HandleEntity: [SetElementEntity]]
    public let setsUpdatedPublisher: AnyPublisher<[SetEntity], Never>
    public let setElemetsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never>
    public let albumElement: SetElementEntity?
    
    public init(node: NodeEntity? = nil,
                albums: [SetEntity] = [],
                albumContent: [HandleEntity: [SetElementEntity]] = [:],
                setsUpdatedPublisher: AnyPublisher<[SetEntity], Never> = Empty().eraseToAnyPublisher(),
                setElemetsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never> = Empty().eraseToAnyPublisher(),
                albumElement: SetElementEntity? = nil
    ) {
        self.node = node
        self.albums = albums
        self.albumContent = albumContent
        self.setsUpdatedPublisher = setsUpdatedPublisher
        self.setElemetsUpdatedPublisher = setElemetsUpdatedPublisher
        self.albumElement = albumElement
    }
    
    public func albums() async -> [SetEntity] {
        albums
    }
    
    public func albumContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity] {
        albumContent[id] ?? []
    }
    
    public func albumElement(by id: HandleEntity, elementId: HandleEntity) async -> SetElementEntity? {
        albumElement
    }
    
    public func createAlbum(_ name: String?) async throws -> SetEntity {
        SetEntity(handle: HandleEntity(1), userId: HandleEntity(2), coverId: HandleEntity(3), modificationTime: Date(), name: name ?? "")
    }
    
    public func updateAlbumName(_ name: String, _ id: HandleEntity) async throws -> String {
        name
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
        elementId
    }
}
