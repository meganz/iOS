import Combine
import MEGADomain

final public class UserAlbumCacheRepository: UserAlbumRepositoryProtocol {
    public static let newRepo: UserAlbumCacheRepository = UserAlbumCacheRepository(
        userAlbumRepository: UserAlbumRepository.newRepo, userAlbumCache: UserAlbumCache.shared)
    
    private let userAlbumRepository: any UserAlbumRepositoryProtocol
    private let userAlbumCache: any UserAlbumCacheProtocol
    
    public let setsUpdatedPublisher: AnyPublisher<[SetEntity], Never>
    public let setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never>
    
    init(userAlbumRepository: some UserAlbumRepositoryProtocol,
         userAlbumCache: some UserAlbumCacheProtocol) {
        self.userAlbumRepository = userAlbumRepository
        self.userAlbumCache = userAlbumCache
        
        setsUpdatedPublisher = userAlbumRepository.setsUpdatedPublisher
        setElementsUpdatedPublisher = userAlbumRepository.setElementsUpdatedPublisher
    }
    
    public func albums() async -> [SetEntity] {
        let cachedAlbums = await userAlbumCache.albums
        guard cachedAlbums.isEmpty else {
            return cachedAlbums
        }
        let userAlbums = await userAlbumRepository.albums()
        await userAlbumCache.setAlbums(userAlbums)
        return userAlbums
    }
    
    public func albumContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity] {
        await userAlbumRepository.albumContent(by: id, includeElementsInRubbishBin: includeElementsInRubbishBin)
    }
    
    public func albumElement(by id: HandleEntity, elementId: HandleEntity) async -> SetElementEntity? {
        await userAlbumRepository.albumElement(by: id, elementId: elementId)
    }
    
    public func createAlbum(_ name: String?) async throws -> SetEntity {
        try await userAlbumRepository.createAlbum(name)
    }
    
    public func updateAlbumName(_ name: String, _ id: HandleEntity) async throws -> String {
        try await userAlbumRepository.updateAlbumName(name, id)
    }
    
    public func deleteAlbum(by id: HandleEntity) async throws -> HandleEntity {
        try await userAlbumRepository.deleteAlbum(by: id)
    }
    
    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        try await userAlbumRepository.addPhotosToAlbum(by: id, nodes: nodes)
    }
    
    public func updateAlbumElementName(albumId: HandleEntity, elementId: HandleEntity, name: String) async throws -> String {
        try await userAlbumRepository.updateAlbumElementName(albumId: albumId, elementId: elementId, name: name)
    }
    
    public func updateAlbumElementOrder(albumId: HandleEntity, elementId: HandleEntity, order: Int64) async throws -> Int64 {
        try await userAlbumRepository.updateAlbumElementOrder(albumId: albumId, elementId: elementId, order: order)
    }
    
    public func deleteAlbumElements(albumId: HandleEntity, elementIds: [HandleEntity]) async throws -> AlbumElementsResultEntity {
        try await userAlbumRepository.deleteAlbumElements(albumId: albumId, elementIds: elementIds)
    }
    
    public func updateAlbumCover(for albumId: HandleEntity, elementId: HandleEntity) async throws -> HandleEntity {
        try await userAlbumRepository.updateAlbumCover(for: albumId, elementId: elementId)
    }
}
