import Foundation
import MEGADomain
import MEGAPresentation

actor SpotlightContentIndexerActor {
    
    private let favouritesUseCase: any FavouriteNodesUseCaseProtocol
    private let nodeAttributeUseCase: any NodeAttributeUseCaseProtocol
    private let spotlightSearchableIndexUseCase: any SpotlightSearchableIndexUseCaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    
    private enum Constants {
        static let favouritesId = "favourites"
    }
    
    init(favouritesUseCase: some FavouriteNodesUseCaseProtocol, 
         nodeAttributeUseCase: some NodeAttributeUseCaseProtocol,
         spotlightSearchableIndexUseCase: some SpotlightSearchableIndexUseCaseProtocol,
         remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase
    ) {
        self.favouritesUseCase = favouritesUseCase
        self.nodeAttributeUseCase = nodeAttributeUseCase
        self.spotlightSearchableIndexUseCase = spotlightSearchableIndexUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }
    
    func indexSearchableItems() async {
        do {
            try await spotlightSearchableIndexUseCase.deleteAllSearchableItems()
            let items = try await fetchSearchableItems()
            try await spotlightSearchableIndexUseCase.indexSearchableItems(items)
            MEGALogDebug("[Spotlight] \(items.count) Favourites indexed")
        } catch {
            MEGALogError("[Spotlight] Indexing favourites error: \(error.localizedDescription)")
        }
    }
    
    func deleteAllSearchableItems() async {
        do {
            try await spotlightSearchableIndexUseCase.deleteAllSearchableItems()
            MEGALogDebug("[Spotlight] All searchable items deindexed")
        } catch {
            MEGALogDebug("[Spotlight] Deindexing all searchable items error: \(error.localizedDescription)")
        }
    }
    
    func reindex(updatedNodes: [NodeEntity]) async {
        
        if remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) {
            
            let acceptedNodeChanges = updatedNodes
                .nodes(for: [.favourite, .sensitive, .name, .removed])
            
            guard acceptedNodeChanges.notContains(where: { $0.changeTypes.contains(.sensitive) && $0.isFolder }) else {
                await indexSearchableItems()
                return
            }
            
            await withTaskGroup(of: Void.self) { taskGroup in
                taskGroup.addTasksUnlessCancelled(for: acceptedNodeChanges) { [weak self] node in
                    guard let self else {
                        return
                    }
                    
                    if node.isMarkedSensitive || !node.isFavourite || node.changeTypes.contains(.removed) {
                        await deIndex(node: node)
                    } else if node.isFavourite {
                        await index(node: node)
                    }
                }
            }
        } else {
            let acceptedNodeChanges = updatedNodes
                .nodes(for: [.favourite, .name, .removed])

            await withTaskGroup(of: Void.self) { taskGroup in
                taskGroup.addTasksUnlessCancelled(for: acceptedNodeChanges) { [weak self] node in
                    guard let self else {
                        return
                    }
                    
                    if !node.isFavourite || node.changeTypes.contains(.removed) {
                        await deIndex(node: node)
                    } else if node.isFavourite {
                        await index(node: node)
                    }
                }
            }
        }
    }
    
    private func fetchSearchableItems() async throws -> [SpotlightSearchableItemEntity] {
        try await favouritesUseCase
            .allFavouriteNodes(
                searchString: nil,
                excludeSensitives: remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
                limit: 100)
            .map(searchableItem(node:))
    }
    
    private func index(node: NodeEntity) async {
        do {
            let item = searchableItem(node: node)
            try await spotlightSearchableIndexUseCase.indexSearchableItems([item])
            MEGALogDebug("[Spotlight] \(node.base64Handle) indexed")
        } catch {
            MEGALogError("[Spotlight] Indexing \(node.base64Handle) error: \(error.localizedDescription)")
        }
    }
    
    private func deIndex(node: NodeEntity) async {
        do {
            try await spotlightSearchableIndexUseCase.deleteSearchableItems(withIdentifiers: [node].map(\.base64Handle))
        } catch {
            MEGALogError("[Spotlight] Deindexing \(node.base64Handle) error: \(error.localizedDescription)")
        }
    }
        
    private func searchableItem(node: NodeEntity) -> SpotlightSearchableItemEntity {
        
        let content: (description: String?, thumbnailData: Data?) = if node.isFile {
            (ByteCountFormatter.string(fromByteCount: Int64(node.size), countStyle: .file), UIImage.spotlightFile.pngData())
        } else {
            (nodeAttributeUseCase.pathFor(node: node), UIImage.spotlightFolder.pngData())
        }
        
        return SpotlightSearchableItemEntity(
            uniqueIdentifier: node.base64Handle,
            domainIdentifier: Constants.favouritesId,
            contentType: .data,
            title: node.name,
            contentDescription: content.description,
            thumbnailData: content.thumbnailData)
    }
}
