import ChatRepo
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

protocol PhotoBrowserDataProviderProtocol: Sendable {
    init(currentPhoto: NodeEntity, allPhotos: [NodeEntity], sdk: MEGASdk, nodeProvider: any MEGANodeProviderProtocol)
    var allPhotoEntities: [NodeEntity] { get }
    var allPhotos: [MEGANode] { get }

    /// Deprecate usage of currentPhoto, in favour of using currentPhoto() async. Currently using this computed var will not work for scenario that are public albums, as the node need to be fetched before hand.
    var currentPhoto: MEGANode? { get }
    
    func currentPhoto() async -> MEGANode?
}

final class PhotoBrowserDataProvider: NSObject, @unchecked Sendable, PhotoBrowserDataProviderProtocol {
    @Atomic private var megaNodes: [MEGANode]?
    @Atomic private var nodeEntities: [NodeEntity]?
    @Atomic @objc var currentIndex: Int = 0
    @Atomic private var areHandlesUnique: Bool?

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
    
    /// Identity of the photo at `index`, or `.invalid` when the index is out of range.
    ///
    /// Views, zoom scales and in-flight loads are keyed on this rather than on the index: pages
    /// prepended above the loaded range shift every index, and a deletion shifts everything after
    /// it, so an index identifies a slot but not a photo.
    func handle(at index: Int) -> HandleEntity {
        if let nodes = megaNodes {
            return nodes[safe: index]?.handle ?? .invalid
        }
        return nodeEntities?[safe: index]?.handle ?? .invalid
    }

    /// Key for the view and zoom caches, or `nil` when the slot at `index` is empty.
    ///
    /// Normally the node's handle, so a page view and a zoom scale follow the photo rather than the
    /// slot: a page prepended above the loaded range shifts every index, and so does a deletion.
    ///
    /// Handles are only unique when the list is, though, and one list is not: chat attachments are
    /// built one per message, so attaching or forwarding the same node twice puts it in twice. There
    /// the index is the only thing that tells the two apart, and it is safe to use — that list is
    /// handed over whole, so nothing ever shifts it.
    @objc func cacheKey(at index: Int) -> NSNumber? {
        guard handlesAreUnique else {
            return (0..<count).contains(index) ? NSNumber(value: index) : nil
        }
        let handle = handle(at: index)
        return handle == .invalid ? nil : NSNumber(value: handle)
    }

    /// Worked out once: the list only ever shrinks or gains de-duplicated pages after this, so a
    /// list without repeats cannot grow any.
    private var handlesAreUnique: Bool {
        if let areHandlesUnique { return areHandlesUnique }
        let handles = megaNodes?.map(\.handle) ?? nodeEntities?.map(\.handle) ?? []
        let unique = Set(handles).count == handles.count
        $areHandlesUnique.mutate { $0 = unique }
        return unique
    }

    @objc var currentCacheKey: NSNumber? {
        cacheKey(at: $currentIndex.wrappedValue)
    }

    func photoNode(forHandle handle: HandleEntity) async -> MEGANode? {
        if let nodes = megaNodes {
            return nodes.first { $0.handle == handle }
        }
        guard nodeEntities?.contains(where: { $0.handle == handle }) == true else { return nil }
        return await nodeProvider.node(for: handle)
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
                nodeProvider: nodeProvider,
                chatNodeProvider: ChatMEGANodeProvider(chatSdk: MEGAChatSdk.sharedChatSdk, sdk: MEGASdk.shared)
            ),
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
    
    /// Appends a page fetched beyond the end of the loaded range.
    ///
    /// - Returns: how many nodes were actually added. Only the entity-backed providers paginate —
    ///   the `MEGANode` initialisers serve entry points that are handed their whole list up front.
    @discardableResult
    func appendPhotos(_ nodes: [NodeEntity]) -> Int {
        let added = newPhotos(from: nodes)
        guard !added.isEmpty else { return 0 }
        $nodeEntities.mutate { $0?.append(contentsOf: added) }
        return added.count
    }

    /// Inserts a page fetched before the start of the loaded range, moving the current photo along
    /// with it so the user keeps looking at the same thing.
    ///
    /// - Returns: how many nodes were actually inserted — the caller needs it to shift the pages
    ///   already laid out in the scroll view by the same amount.
    @discardableResult
    func prependPhotos(_ nodes: [NodeEntity]) -> Int {
        let added = newPhotos(from: nodes)
        guard !added.isEmpty else { return 0 }
        $nodeEntities.mutate { $0?.insert(contentsOf: added, at: 0) }
        $currentIndex.mutate { $0 += added.count }
        return added.count
    }

    private func newPhotos(from nodes: [NodeEntity]) -> [NodeEntity] {
        guard megaNodes == nil, nodeEntities != nil else { return [] }
        let loaded = Set(nodeEntities?.map(\.handle) ?? [])
        var seen: Set<HandleEntity> = []
        return nodes.filter { !loaded.contains($0.handle) && seen.insert($0.handle).inserted }
    }

    private func removePhotosForNodeEntities(by nodeList: [NodeEntity]) {
        let photosSet = Set(nodeEntities ?? [])
        let updatedSet = Set(nodeList.removedChangeTypeNodes())
        let removedPhotos = photosSet.intersection(updatedSet)
        
        guard let count = nodeEntities?.count, count > 0  else {
            return
        }
        
        let safeIndex = min($currentIndex.wrappedValue, count - 1)
        let preCurrentIndexPhotoSet = Set(nodeEntities?.prefix(through: safeIndex) ?? [])

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
