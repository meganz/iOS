import MEGADomain
import MEGASdk
import MEGASwift

public protocol PublicAlbumNodeProviderProtocol: MEGANodeProviderProtocol {
    
    /// The MEGANode for `SetElementEntity`
    ///
    /// If the node is cached it will be returned immediately.
    ///
    /// Task to retrieve the node will be created and stored into `PublicAlbumNodeCache` as `inProgress` untill its loaded.
    /// On load successful the `MEGANode` will be stored in cache as `ready` and returned. On failure the cached
    ///  `inProgress(Task<MEGANode?, any Error>)` entry will be removed.
    ///
    /// - Parameter element: SetElementEntity to retrieve and cache node
    /// - Returns: MEGANode or nil if not found.
    func publicPhotoNode(for element: SetElementEntity) async throws -> MEGANode?
    
    /// Clear node cache
    func clearCache() async
}

/// The `PublicAlbumNodeProvider` retrieve and cache `MEGANode` for a public album link
public final class PublicAlbumNodeProvider: PublicAlbumNodeProviderProtocol {
    
    private let sdk: MEGASdk
    private let nodeCache = PublicAlbumNodeCache()
    
    public static let shared = PublicAlbumNodeProvider(sdk: .sharedSdk)
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func node(for handle: HandleEntity) async -> MEGANode? {
        if let node = try? await nodeCache.node(handle: handle) {
            return node
        }
        return await nodeFromPreview(handle: handle)
    }
    
    public func publicPhotoNode(for element: SetElementEntity) async throws -> MEGANode? {
        if let node = try await nodeCache.node(handle: element.nodeId) {
            return node
        }
        let task = makePreviewElementNodeTask(elementId: element.handle)
        await nodeCache.setCacheEntry(handle: element.nodeId, entry: .inProgress(task))
        do {
            let megaNode = try await task.value
            await nodeCache.setCacheEntry(handle: element.nodeId, entry: .ready(megaNode))
            return megaNode
        } catch {
            await nodeCache.removeCacheEntry(handle: element.nodeId)
            throw error
        }
    }
    
    public func clearCache() async {
        await nodeCache.clear()
    }
    
    // MARK: - Private
    private func nodeFromPreview(handle: HandleEntity) async -> MEGANode? {
        guard let setElement = sdk.publicSetElementsInPreview()
            .first(where: { $0.nodeId == handle })?.toSetElementEntity() else {
            return nil
        }
        return try? await publicPhotoNode(for: setElement)
    }
    
    private func makePreviewElementNodeTask(elementId: HandleEntity) -> Task<MEGANode?, any Error> {
        Task {
            try await withAsyncThrowingValue { completion in
                sdk.previewElementNode(elementId, delegate: RequestDelegate { result in
                    switch result {
                    case .success(let request):
                        completion(.success(request.publicNode))
                    case .failure(let error):
                        let errorEntity: any Error
                        switch error.type {
                        case .apiEArgs:
                            errorEntity = SharedPhotoErrorEntity.photoNotFound
                        case .apiEAccess:
                            errorEntity = SharedPhotoErrorEntity.previewModeNotEnabled
                        default:
                            errorEntity = GenericErrorEntity()
                        }
                        completion(.failure(errorEntity))
                    }
                })
            }
        }
    }
}

/// The state of the current MEGANode
private enum PublicAlbumNodeCacheEntry {
    case inProgress(Task<MEGANode?, any Error>)
    case ready(MEGANode?)
}

/// `PublicAlbumPhotoNodeCacheEntryProxy` class wrapper thats stored in `NSCache`
private final class PublicAlbumPhotoNodeCacheEntryProxy {
    let entry: PublicAlbumNodeCacheEntry
    init(entry: PublicAlbumNodeCacheEntry) { self.entry = entry }
}

/// The `PublicAlbumNodeCache` will store the `MEGANode`s into `NSCache`
private actor PublicAlbumNodeCache {
    private let nodeCache: NSCache<NSNumber, PublicAlbumPhotoNodeCacheEntryProxy> = NSCache()
    
    /// The cached MEGANode for `HandleEntity`
    ///
    /// If the cache entry is `ready` the node will be returned immediately.
    /// If the cache entry is `inProgress` it will wait for the task to complete before returning the node or throw error
    ///
    /// - Parameter handle: associated MEGANode to retrieve
    func node(handle: HandleEntity) async throws -> MEGANode? {
        if let cached = nodeCache[handle] {
            switch cached {
            case .ready(let node):
                return node
            case .inProgress(let task):
                return try await task.value
            }
        }
        return nil
    }
    
    /// Sets the cached `PublicAlbumNodeCacheEntry` for `HandleEntity`
    ///
    /// - Parameter handle: handle to update cache entry
    /// - Parameter entry: class wrapper for `PublicAlbumNodeCacheEntry`
    func setCacheEntry(handle: HandleEntity, entry: PublicAlbumNodeCacheEntry) {
        nodeCache[handle] = entry
    }
    
    /// Remove  the cached `PublicAlbumNodeCacheEntry` for `HandleEntity`
    ///
    /// - Parameter handle: handle to remove cache entry
    func removeCacheEntry(handle: HandleEntity) {
        nodeCache[handle] = nil
    }

    /// Remove  all `PublicAlbumNodeCacheEntry` items
    func clear() {
        nodeCache.removeAllObjects()
    }
}

private extension NSCache where KeyType == NSNumber, ObjectType == PublicAlbumPhotoNodeCacheEntryProxy {
    subscript(_ handle: HandleEntity) -> PublicAlbumNodeCacheEntry? {
        get {
            object(forKey: NSNumber(value: handle))?.entry
        }
        set {
            let key = NSNumber(value: handle)
            if let entry = newValue {
                let value = PublicAlbumPhotoNodeCacheEntryProxy(entry: entry)
                setObject(value, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }
}
