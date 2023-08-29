import Foundation
import MEGADomain
import MEGASDKRepo

protocol PhotoBrowserDataProviderProtocol {
    init(currentPhoto: NodeEntity, allPhotos: [NodeEntity], sdk: MEGASdk, nodeProvider: any MEGANodeProviderProtocol)
    var allPhotoEntities: [NodeEntity] { get }
    
    /// Deprecate usage of currentPhoto, in favour of using currentPhoto() async. Currently using this computed var will not work for scenario that are public albums, as the node need to be fetched before hand.
    var currentPhoto: MEGANode? { get }
    
    func currentPhoto() async -> MEGANode?
}

final class PhotoBrowserDataProvider: NSObject, PhotoBrowserDataProviderProtocol {
    private var nodeStore: ElementStore<MEGANode, UInt64>
    private var megaNodes: [MEGANode]?
    private var nodeEntities: [NodeEntity]?
    private let sdk: MEGASdk
    private let nodeProvider: any MEGANodeProviderProtocol
    
    @objc var currentIndex: Int = 0
    
    @objc init(currentPhoto: MEGANode, allPhotos: [MEGANode], sdk: MEGASdk) {
        megaNodes = allPhotos
        nodeStore = .init(currentIndex: allPhotos.firstIndex(of: currentPhoto), elements: allPhotos, elementsIdentifiedBy: \.handle)
        self.sdk = sdk
        self.nodeProvider = DefaultMEGANodeProvider(sdk: sdk)
        if let index = allPhotos.firstIndex(of: currentPhoto) {
            currentIndex = index
        }
        
        super.init()
    }
    
    @objc init(currentIndex: Int, allPhotos: [MEGANode], sdk: MEGASdk) {
        megaNodes = allPhotos
        nodeStore = .init(currentIndex: currentIndex, elements: allPhotos, elementsIdentifiedBy: \.handle)
        self.sdk = sdk
        if allPhotos.indices ~= currentIndex {
            self.currentIndex = currentIndex
        }
        self.nodeProvider = DefaultMEGANodeProvider(sdk: sdk)
        super.init()
    }
    
    init(currentPhoto: NodeEntity, allPhotos: [NodeEntity], sdk: MEGASdk, nodeProvider: any MEGANodeProviderProtocol) {
        nodeEntities = allPhotos
        nodeStore = .init(elementsIdentifiedBy: \.handle)
        self.sdk = sdk
        self.nodeProvider = nodeProvider
        currentIndex = allPhotos.firstIndex(of: currentPhoto) ?? 0
        
        super.init()
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
            return nodes[safe: currentIndex]
        } else {
            return nodeEntities?[safe: currentIndex]?.toMEGANode(in: sdk)
        }
    }
    
    @objc func currentPhoto() async -> MEGANode? {
        await photoNode(at: currentIndex)
    }
    
    var currentPhotoNodeEntity: NodeEntity? {
        if let nodes = megaNodes {
            return nodes[safe: currentIndex]?.toNodeEntity()
        } else {
            return nodeEntities?[safe: currentIndex]
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
        nodeEntities = photos.toNodeEntities()
        megaNodes = photos
    }
    
    @objc var allPhotos: [MEGANode] {
        if let nodes = megaNodes {
            return nodes
        } else {
            return nodeEntities?.toMEGANodes(in: sdk) ?? []
        }
    }
    
    @objc func shouldUpdateCurrentIndex(toIndex index: Int) -> Bool {
        currentIndex != index && isValid(index: index)
    }
    
    @objc func updatePhoto(by request: MEGARequest) {
        if megaNodes != nil, let node = request.toMEGANode(in: sdk), let index = megaNodes?.firstIndex(of: node) {
            megaNodes?[index] = node
        } else if let node = request.toNodeEntity(in: sdk), let index = nodeEntities?.firstIndex(of: node) {
            nodeEntities?[index] = node
        }
    }
        
    @MainActor
    @objc func removePhotos(in nodeList: MEGANodeList?) async -> Int {
        guard let nodeList else { return .zero }
        if megaNodes != nil {
            // just assigning the filtered value to mega nodes was overriding a correct value of name
            // checking for count difference to decide if we need to update the array at all [IOS-7448]
            // issue is generaly caused that the same data is cached in three places
            // and synchronizing is very tricky to remember
            await nodeStore.updateCurrent(index: currentIndex)
            let changedNodes = await nodeStore.remove(nodeList.toNodeArray().removedChangeTypeNodes())
            if self.megaNodes?.count != changedNodes.count {
                self.megaNodes = changedNodes
            }
            self.currentIndex = await nodeStore.currentIndex
            return await nodeStore.count
        } else {
            removePhotosForNodeEntities(by: nodeList.toNodeEntities())
            return self.count
        }
    }
    
    @objc func updatePhotos(in nodeList: MEGANodeList) {
        if megaNodes != nil {
            updatePhotosForMEGANodes(by: nodeList)
        } else {
            updatePhotosForNodeEntities(by: nodeList)
        }
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
                sdk: sdk,
                sharedFolderSdk: displayMode == .nodeInsideFolderLink ? sdk : nil,
                nodeProvider: nodeProvider),
            fileCacheRepository: FileCacheRepository.newRepo,
            nodeRepository: NodeRepository.newRepo)
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
        let preCurrentIndexPhotoSet = Set(nodeEntities?.prefix(through: currentIndex) ?? [])

        for photo in removedPhotos {
            nodeEntities?.remove(object: photo)
        }
        
        let preCurrentIndexRemovedPhotoCount = preCurrentIndexPhotoSet.intersection(removedPhotos).count
        currentIndex = max(currentIndex - preCurrentIndexRemovedPhotoCount, 0)
    }
    
    private func updatePhotosForMEGANodes(by nodeList: MEGANodeList) {
        let photosSet = Set(megaNodes ?? [])
        var updatedSet = Set(nodeList.toNodeArray().nodes(for: [.attributes, .publicLink]))
        updatedSet.formIntersection(photosSet)
        
        for photo in updatedSet {
            if let index = megaNodes?.firstIndex(of: photo) {
                megaNodes?[index] = photo
            }
        }
    }
    
    private func updatePhotosForNodeEntities(by nodeList: MEGANodeList) {
        let photosSet = Set(nodeEntities ?? [])
        var updatedSet = Set(nodeList.toNodeEntities().nodes(for: [.attributes, .publicLink]))
        updatedSet.formIntersection(photosSet)
        
        for photo in updatedSet {
            if let index = nodeEntities?.firstIndex(of: photo) {
                nodeEntities?[index] = photo
            }
        }
    }
}
