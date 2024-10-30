import Foundation
import MEGASwift

public protocol ShareCollectionUseCaseProtocol: Sendable {
    func shareCollectionLink(_ collection: SetEntity) async throws -> String?
    func shareLink(forCollections collections: [SetEntity]) async -> [SetIdentifier: String]
    func removeSharedLink(forCollectionId collectionId: SetIdentifier) async throws
    func removeSharedLink(forCollections collectionIds: [SetIdentifier]) async -> [SetIdentifier]
    
    ///  Determines if the given sequence of Collection Entities contains any sensitive elements in them.
    /// - Parameter collections: Sequence of SetEntities to iterate over and determine if any contain sensitive elements
    /// - Returns: True, if any collections contains a sensitive element, else false.
    func doesCollectionsContainSensitiveElement(for collections: some Sequence<SetEntity>) async throws -> Bool
}

public struct ShareCollectionUseCase: ShareCollectionUseCaseProtocol {
    private let shareAlbumRepository: any ShareCollectionRepositoryProtocol
    private let userAlbumRepository: any UserAlbumRepositoryProtocol
    private let nodeRepository: any NodeRepositoryProtocol
    
    public init(
        shareAlbumRepository: some ShareCollectionRepositoryProtocol,
        userAlbumRepository: some UserAlbumRepositoryProtocol,
        nodeRepository: some NodeRepositoryProtocol) {
            self.shareAlbumRepository = shareAlbumRepository
            self.userAlbumRepository = userAlbumRepository
            self.nodeRepository = nodeRepository
        }
    
    public func shareCollectionLink(_ collection: SetEntity) async throws -> String? {
        try await shareAlbumRepository.shareCollectionLink(collection)
    }
    
    public func shareLink(forCollections collections: [SetEntity]) async -> [SetIdentifier: String] {
        await withTaskGroup(of: (SetIdentifier, String?).self) { group in
            collections.forEach { collection in
                group.addTask {
                    return (collection.setIdentifier, try? await shareCollectionLink(collection))
                }
            }
            return await group.reduce(into: [SetIdentifier: String](), {
                $0[$1.0] = $1.1
            })
        }
    }
    
    public func removeSharedLink(forCollectionId collectionId: SetIdentifier) async throws {
        try await shareAlbumRepository.removeSharedLink(forCollectionId: collectionId)
    }
    
    public func removeSharedLink(forCollections collectionIds: [SetIdentifier]) async -> [SetIdentifier] {
        await withTaskGroup(of: SetIdentifier?.self) { group in
            collectionIds.forEach { collectionId in
                group.addTask {
                    do {
                        try await removeSharedLink(forCollectionId: collectionId)
                        return collectionId
                    } catch {
                        return nil
                    }
                }
            }
            
            return await group.reduce(into: [SetIdentifier](), {
                if let removeShareLinkAlbumId = $1 { $0.append(removeShareLinkAlbumId) }
            })
        }
    }
    
    public func doesCollectionsContainSensitiveElement(for collections: some Sequence<SetEntity>) async throws -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { taskGroup in
            taskGroup.addTasksUnlessCancelled(for: collections, operation: doesCollectionContainSensitiveNode(album:))
            let doesCollectionContainSensitiveNode = try await taskGroup.contains(true)
            taskGroup.cancelAll()
            return doesCollectionContainSensitiveNode
        }
    }
}

extension ShareCollectionUseCase {
    
    @Sendable
    private func doesCollectionContainSensitiveNode(album: SetEntity) async throws -> Bool {
        switch album.setType {
        case .invalid:
            throw GenericErrorEntity()
        case .album:
            return try await doesAlbumContainSensitiveNode(album: album)
        case .playlist:
            return false
        }
    }
    
    private func doesAlbumContainSensitiveNode(album: SetEntity) async throws -> Bool {
        return try await withThrowingTaskGroup(of: Bool.self) { taskGroup in
            let albumElementIds = await userAlbumRepository.albumElementIds(by: album.handle, includeElementsInRubbishBin: false)
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
