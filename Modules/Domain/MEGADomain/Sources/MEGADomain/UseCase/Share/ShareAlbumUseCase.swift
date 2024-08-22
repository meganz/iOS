import Foundation
import MEGASwift

public protocol ShareAlbumUseCaseProtocol: Sendable {
    func shareAlbumLink(_ album: AlbumEntity) async throws -> String?
    func shareLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity: String]
    func removeSharedLink(forAlbum album: AlbumEntity) async throws
    func removeSharedLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity]
    
    ///  Determines if the given sequence of Album Entities contains any sensitive elements in them.
    /// - Parameter albums: Sequence of AlbumEntities to iterate over and determine if any contain sensitive elements
    /// - Returns: True, if any albums contains a sensitive element, else false.
    func doesAlbumsContainSensitiveElement(for albums: some Sequence<AlbumEntity>) async throws -> Bool
}

public struct ShareAlbumUseCase: ShareAlbumUseCaseProtocol {
    private let shareAlbumRepository: any ShareAlbumRepositoryProtocol
    private let userAlbumRepository: any UserAlbumRepositoryProtocol
    private let nodeRepository: any NodeRepositoryProtocol
    
    public init(
        shareAlbumRepository: some ShareAlbumRepositoryProtocol,
        userAlbumRepository: some UserAlbumRepositoryProtocol,
        nodeRepository: some NodeRepositoryProtocol) {
        self.shareAlbumRepository = shareAlbumRepository
        self.userAlbumRepository = userAlbumRepository
        self.nodeRepository = nodeRepository
    }
    
    public func shareAlbumLink(_ album: AlbumEntity) async throws -> String? {
        guard album.type == .user else {
            throw ShareCollectionErrorEntity.invalidCollectionType
        }
        return try await shareAlbumRepository.shareAlbumLink(album)
    }
    
    public func shareLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity: String] {
        await withTaskGroup(of: (HandleEntity, String?).self) { group in
            albums.forEach { album in
                group.addTask {
                    return (album.id, try? await shareAlbumLink(album))
                }
            }
            return await group.reduce(into: [HandleEntity: String](), {
                $0[$1.0] = $1.1
            })
        }
    }
    
    public func removeSharedLink(forAlbum album: AlbumEntity) async throws {
        guard album.type == .user else {
            throw ShareCollectionErrorEntity.invalidCollectionType
        }
        try await shareAlbumRepository.removeSharedLink(forAlbumId: album.id)
    }
    
    public func removeSharedLink(forAlbums albums: [AlbumEntity]) async -> [HandleEntity] {
        await withTaskGroup(of: HandleEntity?.self) { group in
            albums.forEach { album in
                group.addTask {
                    do {
                        try await removeSharedLink(forAlbum: album)
                        return album.id
                    } catch {
                        return nil
                    }
                }
            }
            
            return await group.reduce(into: [HandleEntity](), {
                if let removeShareLinkAlbumId = $1 { $0.append(removeShareLinkAlbumId) }
            })
        }
    }
    
    public func doesAlbumsContainSensitiveElement(for albums: some Sequence<AlbumEntity>) async throws -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { taskGroup in
            taskGroup.addTasksUnlessCancelled(for: albums, operation: doesAlbumContainSensitiveNode(album:))
            let doesAlbumContainSensitiveNode = try await taskGroup.contains(true)
            taskGroup.cancelAll()
            return doesAlbumContainSensitiveNode
        }
    }
}

extension ShareAlbumUseCase {
    
    @Sendable
    private func doesAlbumContainSensitiveNode(album: AlbumEntity) async throws -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { taskGroup in
            let albumElementIds = await userAlbumRepository.albumElementIds(by: album.id, includeElementsInRubbishBin: false)
            taskGroup.addTasksUnlessCancelled(for: albumElementIds) { albumElementId in
                if let photo = nodeRepository.nodeForHandle(albumElementId.nodeId) {
                    photo.isMarkedSensitive ? true : try await nodeRepository.isInheritingSensitivity(node: photo)
                } else {
                    false
                }
            }
            
            let doesContainSensitiveNode = try await taskGroup.contains(true)
            taskGroup.cancelAll()
            return doesContainSensitiveNode
        }
    }
}
