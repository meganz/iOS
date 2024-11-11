@preconcurrency import Combine
import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

public protocol UserAlbumCacheRepositoryMonitorsProtocol: Sendable {
    var setUpdateAsyncSequences: AnyAsyncSequence<[SetEntity]> { get async }
    var setElementUpdateAsyncSequences: AnyAsyncSequence<[SetElementEntity]> { get async }
    var setElementUpdateOnSetsAsyncSequences: AnyAsyncSequence<[SetEntity]> { get async }
    var setsUpdatedPublisher: AnyPublisher<[SetEntity], Never> { get }
    var setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never> { get }
    func monitorSetUpdates() async
    func monitorSetElementUpdates() async
    func monitorCacheInvalidationTriggers() async
}

public struct UserAlbumCacheRepositoryMonitors: UserAlbumCacheRepositoryMonitorsProtocol {
    public var setUpdateAsyncSequences: AnyAsyncSequence<[SetEntity]> {
        get async {
            await setUpdateSequences.make()
        }
    }
    public var setElementUpdateAsyncSequences: AnyAsyncSequence<[SetElementEntity]> {
        get async {
            await setElementUpdateSequences.make()
        }
    }
    public var setElementUpdateOnSetsAsyncSequences: AnyAsyncSequence<[SetEntity]> {
        get async {
            await setElementUpdateOnSetsSequences.make()
        }
    }
    public var setsUpdatedPublisher: AnyPublisher<[SetEntity], Never> {
        setsUpdatedSourcePublisher.eraseToAnyPublisher()
    }
    
    public var setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never> {
        setElementsUpdatedSourcePublisher.eraseToAnyPublisher()
    }
    
    private let sdk: MEGASdk
    private let setAndElementsUpdatesProvider: any SetAndElementUpdatesProviderProtocol
    private let userAlbumCache: any UserAlbumCacheProtocol
    private let cacheInvalidationTrigger: CacheInvalidationTrigger
    private let setUpdateSequences = MulticastAsyncSequence<[SetEntity]>()
    private let setElementUpdateSequences = MulticastAsyncSequence<[SetElementEntity]>()
    private let setElementUpdateOnSetsSequences = MulticastAsyncSequence<[SetEntity]>()
    private let setsUpdatedSourcePublisher = PassthroughSubject<[SetEntity], Never>()
    private let setElementsUpdatedSourcePublisher = PassthroughSubject<[SetElementEntity], Never>()
    
    public init(sdk: MEGASdk,
                setAndElementsUpdatesProvider: any SetAndElementUpdatesProviderProtocol,
                userAlbumCache: any UserAlbumCacheProtocol,
                cacheInvalidationTrigger: CacheInvalidationTrigger) {
        self.sdk = sdk
        self.setAndElementsUpdatesProvider = setAndElementsUpdatesProvider
        self.userAlbumCache = userAlbumCache
        self.cacheInvalidationTrigger = cacheInvalidationTrigger
    }
    
    public func monitorSetUpdates() async {
        MEGALogDebug("Monitor set updates started")
        for await setUpdates in setAndElementsUpdatesProvider.setUpdates(filteredBy: [.album]) {
            guard !Task.isCancelled else {
                await setUpdateSequences.terminateContinuations()
                break
            }
            
            let (insertions, deletions) = setUpdates
                .reduce(into: (insertions: [SetEntity], deletions: [SetEntity])([], [])) { result, setEntity in
                    if setEntity.changeTypes.contains(.removed) {
                        result.deletions.append(setEntity)
                    } else {
                        result.insertions.append(setEntity.copyWithModified(changeTypes: []))
                    }
                }
            
            await userAlbumCache.remove(albums: deletions)
            await userAlbumCache.setAlbums(insertions)
            
            setsUpdatedSourcePublisher.send(setUpdates)
            await setUpdateSequences.yield(element: setUpdates)
        }
        MEGALogWarning("Monitor set updates stopped")
    }
    
    public func monitorSetElementUpdates() async {
        MEGALogDebug("Monitor set element updates started")
        for await setElementUpdate in setAndElementsUpdatesProvider.setElementUpdates() {
            guard !Task.isCancelled else {
                break
            }
            
            let (insertion, deletions) = setElementUpdate
                .reduce(into: (insertions: [AlbumPhotoIdEntity], deletions: [AlbumPhotoIdEntity])([], [])) { result, setElementEntity in
                    if setElementEntity.changeTypes.contains(.removed) {
                        result.deletions.append(setElementEntity.toAlbumPhotoIdEntity())
                    } else if setElementEntity.changeTypes.contains(.new) {
                        result.insertions.append(setElementEntity.toAlbumPhotoIdEntity())
                    }
                }
            
            await userAlbumCache.remove(elements: deletions)
            await userAlbumCache.insert(elements: insertion)
            
            let updatedAlbums = await withTaskGroup(of: SetEntity?.self, returning: [SetEntity].self) { taskGroup in
                setElementUpdate
                    .forEach { set in
                        taskGroup.addTask { await album(for: set.ownerId) }
                    }
                
                return await taskGroup.reduce(into: [SetEntity](), { if let set = $1 { $0.append(set) } })
            }
            
            setElementsUpdatedSourcePublisher.send(setElementUpdate)
            await setElementUpdateSequences.yield(element: setElementUpdate)
            await setElementUpdateOnSetsSequences.yield(element: updatedAlbums)
        }
        MEGALogWarning("Monitor set element updates stopped")
    }
    
    public func monitorCacheInvalidationTriggers() async {
        MEGALogDebug("Monitor cache invalidation triggers started")
        for await _ in await cacheInvalidationTrigger.cacheInvalidationSequence() {
            guard !Task.isCancelled else {
                break
            }
            await userAlbumCache.removeAllCachedValues(forced: true)
            MEGALogWarning("Cache invalidation triggered forced cleared")
        }
        MEGALogWarning("Monitor cache invalidation triggers stopped")
    }
    
    private func album(for handle: HandleEntity) async -> SetEntity? {
        sdk.setBySid(handle)?.toSetEntity()
    }
}

fileprivate extension SetEntity {
    func copyWithModified(handle: HandleEntity? = nil, userId: HandleEntity? = nil, coverId: HandleEntity? = nil, creationTime: Date? = nil, modificationTime: Date? = nil, setType: SetTypeEntity? = nil, name: String? = nil, isExported: Bool? = nil, changeTypes: SetChangeTypeEntity? = nil) -> SetEntity {
        
        SetEntity(
            handle: handle ?? self.handle,
            userId: userId ?? self.userId,
            coverId: coverId ?? self.coverId,
            creationTime: creationTime ?? self.creationTime,
            modificationTime: modificationTime ?? self.modificationTime,
            setType: setType ?? self.setType,
            name: name ?? self.name,
            isExported: isExported ?? self.isExported,
            changeTypes: changeTypes ?? self.changeTypes)
    }
}
