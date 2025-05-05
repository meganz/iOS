import ChatRepo
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

protocol PhotoBrowserDataProviderProtocol: Sendable {
    init(currentPhoto: NodeEntity, allPhotos: [NodeEntity], sdk: MEGASdk, nodeProvider: any MEGANodeProviderProtocol)
    var allPhotoEntities: [NodeEntity] { get }
    
    /// Deprecate usage of currentPhoto, in favour of using currentPhoto() async. Currently using this computed var will not work for scenario that are public albums, as the node need to be fetched before hand.
    var currentPhoto: MEGANode? { get }
    
    func currentPhoto() async -> MEGANode?
}

final class PhotoBrowserDataProvider: NSObject, @unchecked Sendable, PhotoBrowserDataProviderProtocol {
    @Atomic private var megaNodes: [MEGANode]?
    @Atomic private var nodeEntities: [NodeEntity]?
    @Atomic @objc var currentIndex: Int = 0

    private let sdk: MEGASdk
    private let nodeProvider: any MEGANodeProviderProtocol
    
    @objc init(currentPhoto: MEGANode, allPhotos: [MEGANode], sdk: MEGASdk) {
        self.sdk = sdk
        self.nodeProvider = DefaultMEGANodeProvider(sdk: sdk)
        super.init()

        $megaNodes.mutate { $0 = allPhotos }
        
        if let index = allPhotos.firstIndex(of: currentPhoto) {
            $currentIndex.mutate { $0 = index }
        }
    }
    
    @objc init(currentIndex: Int, allPhotos: [MEGANode], sdk: MEGASdk) {
        self.sdk = sdk
        self.nodeProvider = DefaultMEGANodeProvider(sdk: sdk)
        super.init()

        $megaNodes.mutate { $0 = allPhotos }
        
        if allPhotos.indices ~= currentIndex {
            $currentIndex.mutate { $0 = currentIndex }
        }
    }
    
    init(currentPhoto: NodeEntity, allPhotos: [NodeEntity], sdk: MEGASdk, nodeProvider: any MEGANodeProviderProtocol) {
        self.sdk = sdk
        self.nodeProvider = nodeProvider
        super.init()

        $nodeEntities.mutate { $0 = allPhotos }
        $currentIndex.mutate { $0 = allPhotos.firstIndex(of: currentPhoto) ?? 0 }
    }
    
    func photoNode(at index: Int) async -> MEGANode? {
        if let nodes = megaNodes {
            return nodes[safe: index]
        }
                
        guard let nodeEntity = nodeEntities?[safe: index] else {
            return nil
        }
        
        return await nodeProvider.node(for: nodeEntity.handle)
    }
    
    @objc var count: Int {
        if let nodes = megaNodes {
            return nodes.count
        } else {
            return nodeEntities?.count ?? 0
        }
    }
    
    @objc var currentPhoto: MEGANode? {
        if let nodes = megaNodes {
            return nodes[safe: $currentIndex.wrappedValue]
        } else {
            return nodeEntities?[safe: $currentIndex.wrappedValue]?.toMEGANode(in: sdk)
        }
    }
    
    @objc func currentPhoto() async -> MEGANode? {
        await photoNode(at: $currentIndex.wrappedValue)
    }
    
    var currentPhotoNodeEntity: NodeEntity? {
        if let nodes = megaNodes {
            return nodes[safe: currentIndex]?.toNodeEntity()
        } else {
            return nodeEntities?[safe: $currentIndex.wrappedValue]
        }
    }
    
    var allPhotoEntities: [NodeEntity] {
        if let nodeEntities = nodeEntities {
            return nodeEntities
        } else {
            return megaNodes?.toNodeEntities() ?? []
        }
    }
    
    func fetchOnlyPhotoEntities(mediaUseCase: MediaUseCase) -> [NodeEntity] {
        allPhotoEntities.filter { mediaUseCase.isImage($0.name) }
    }
    
    func convertToNodeEntities(from photos: [MEGANode]) {
        $nodeEntities.mutate { $0 = photos.toNodeEntities() }
        $megaNodes.mutate { $0 = photos }
    }
    
    @objc var allPhotos: [MEGANode] {
        if let nodes = megaNodes {
            return nodes
        } else {
            return nodeEntities?.toMEGANodes(in: sdk) ?? []
        }
    }
    
    @objc func shouldUpdateCurrentIndex(toIndex index: Int) -> Bool {
        $currentIndex.wrappedValue != index && isValid(index: index)
    }
    
    @objc func updatePhoto(by request: MEGARequest) {
        if megaNodes != nil, let node = request.toMEGANode(in: sdk), let index = megaNodes?.firstIndex(of: node) {
            $megaNodes.mutate { $0?[index] = node }
        } else if let node = request.toNodeEntity(in: sdk), let index = nodeEntities?.firstIndex(of: node) {
            $nodeEntities.mutate { $0?[index] = node }
        }
    }
    
    func removePhotos(in nodeEntities: [NodeEntity]) -> Int {
        removePhotosForNodeEntities(by: nodeEntities)
        return self.count
    }
    
    func updatePhotos(in nodes: [NodeEntity]) {
        updatePhotosForNodeEntities(by: nodes)
    }
    
    @objc func updateCurrentIndexTo(_ newIndex: Int) {
        $currentIndex.mutate { $0 = newIndex }
    }
}

// MARK: - Private methods
extension PhotoBrowserDataProvider {
    
    func makeThumbnailUseCase() -> some ThumbnailUseCaseProtocol {
        ThumbnailUseCase(repository: ThumbnailRepository(
            sdk: sdk,
            fileManager: .default,
            nodeProvider: nodeProvider))
    }
        
    func makeSaveMediaToPhotosUseCase(for displayMode: DisplayMode) -> some SaveMediaToPhotosUseCaseProtocol {
        SaveMediaToPhotosUseCase(
            downloadFileRepository: DownloadFileRepository(
                sdk: .shared,
                sharedFolderSdk: displayMode == .nodeInsideFolderLink ? sdk : nil,
                nodeProvider: nodeProvider),
            fileCacheRepository: FileCacheRepository.newRepo,
            nodeRepository: NodeRepository.newRepo,
            chatNodeRepository: ChatNodeRepository.newRepo,
            downloadChatRepository: DownloadChatRepository.newRepo
        )
    }
    
    private func isValid(index: Int) -> Bool {
        if let nodes = megaNodes {
            return nodes.indices ~= index
        } else if let nodes = nodeEntities {
            return nodes.indices ~= index
        } else {
            return false
        }
    }
    
    private func removePhotosForNodeEntities(by nodeList: [NodeEntity]) {
        let photosSet = Set(nodeEntities ?? [])
        let updatedSet = Set(nodeList.removedChangeTypeNodes())
        let removedPhotos = photosSet.intersection(updatedSet)
        let preCurrentIndexPhotoSet = Set(nodeEntities?.prefix(through: $currentIndex.wrappedValue) ?? [])

        for photo in removedPhotos {
            $nodeEntities.mutate { $0?.remove(object: photo) }
        }
        
        let preCurrentIndexRemovedPhotoCount = preCurrentIndexPhotoSet.intersection(removedPhotos).count
        $currentIndex.mutate { $0 = max($0 - preCurrentIndexRemovedPhotoCount, 0) }
    }
    
    private func updatePhotosForNodeEntities(by nodes: [NodeEntity]) {
        let photosSet = Set(nodeEntities ?? [])
        var updatedSet = Set(nodes.nodes(for: [.attributes, .publicLink]))
        updatedSet.formIntersection(photosSet)
        
        for photo in updatedSet {
            if let index = nodeEntities?.firstIndex(of: photo) {
                $nodeEntities.mutate { $0?[index] = photo }
            }
        }
    }
}
