@preconcurrency import Combine
import Foundation
import MEGADomain
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
    
    private let setAndElementsUpdatesProvider: any SetAndElementUpdatesProviderProtocol
    private let userAlbumCache: any UserAlbumCacheProtocol
    private let cacheInvalidationTrigger: CacheInvalidationTrigger
    private let setUpdateSequences = MulticastAsyncSequence<[SetEntity]>()
    private let setElementUpdateSequences = MulticastAsyncSequence<[SetElementEntity]>()
    private let setElementUpdateOnSetsSequences = MulticastAsyncSequence<[SetEntity]>()
    private let setsUpdatedSourcePublisher = PassthroughSubject<[SetEntity], Never>()
    private let setElementsUpdatedSourcePublisher = PassthroughSubject<[SetElementEntity], Never>()
    
    public init(setAndElementsUpdatesProvider: any SetAndElementUpdatesProviderProtocol,
                userAlbumCache: any UserAlbumCacheProtocol,
                cacheInvalidationTrigger: CacheInvalidationTrigger) {
        self.setAndElementsUpdatesProvider = setAndElementsUpdatesProvider
        self.userAlbumCache = userAlbumCache
        self.cacheInvalidationTrigger = cacheInvalidationTrigger
    }
    
    public func monitorSetUpdates() async {
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
    }
    
    public func monitorSetElementUpdates() async {
        for await setElementUpdate in setAndElementsUpdatesProvider.setElementUpdates() {
            guard !Task.isCancelled else {
                break
            }
            
            let invalidateAlbumSets = Set(setElementUpdate.map(\.ownerId))
            
            await userAlbumCache.removeElements(of: invalidateAlbumSets)
            
            setElementsUpdatedSourcePublisher.send(setElementUpdate)
            
            let updatedAlbums = await withTaskGroup(of: SetEntity?.self, returning: [SetEntity].self) { taskGroup in
                invalidateAlbumSets
                    .forEach { albumHandle in
                        taskGroup.addTask { await self.userAlbumCache.album(forHandle: albumHandle) }
                    }
                
                return await taskGroup.reduce(into: [SetEntity](), { if let set = $1 { $0.append(set) } })
            }
            
            await setElementUpdateSequences.yield(element: setElementUpdate)
            await setElementUpdateOnSetsSequences.yield(element: updatedAlbums)
        }
    }
    
    public func monitorCacheInvalidationTriggers() async {
        for await _ in await cacheInvalidationTrigger.cacheInvalidationSequence() {
            guard !Task.isCancelled else {
                break
            }
            await userAlbumCache.removeAllCachedValues(forced: true)
        }
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
