import Foundation
import MEGADomain
import MEGASwift

struct UserAlbumCacheRepositoryMonitors: Sendable {
    
    private let setAndElementsUpdatesProvider: any SetAndElementUpdatesProviderProtocol
    private let setUpdateSequences: MulticastAsyncSequence<[SetEntity]>
    private let userAlbumCache: any UserAlbumCacheProtocol
    private let setElementUpdateSequences: MulticastAsyncSequence<[SetElementEntity]>
    private let setElementUpdateOnSetsSequences: MulticastAsyncSequence<[SetEntity]>
    private let cacheInvalidationTrigger: CacheInvalidationTrigger
    private let setsUpdatedSourcePublisher: @Sendable ([SetEntity]) -> Void
    private let setElementsUpdatedSourcePublisher: @Sendable ([SetElementEntity]) -> Void
    
    init(setAndElementsUpdatesProvider: any SetAndElementUpdatesProviderProtocol,
         setUpdateSequences: MulticastAsyncSequence<[SetEntity]>,
         userAlbumCache: any UserAlbumCacheProtocol,
         setElementUpdateSequences: MulticastAsyncSequence<[SetElementEntity]>,
         setElementUpdateOnSetsSequences: MulticastAsyncSequence<[SetEntity]>,
         cacheInvalidationTrigger: CacheInvalidationTrigger,
         setsUpdatedSourcePublisher: @Sendable @escaping ([SetEntity]) -> Void,
         setElementsUpdatedSourcePublisher: @Sendable @escaping ([SetElementEntity]) -> Void) {
        self.setAndElementsUpdatesProvider = setAndElementsUpdatesProvider
        self.setUpdateSequences = setUpdateSequences
        self.userAlbumCache = userAlbumCache
        self.setElementUpdateSequences = setElementUpdateSequences
        self.setElementUpdateOnSetsSequences = setElementUpdateOnSetsSequences
        self.cacheInvalidationTrigger = cacheInvalidationTrigger
        self.setsUpdatedSourcePublisher = setsUpdatedSourcePublisher
        self.setElementsUpdatedSourcePublisher = setElementsUpdatedSourcePublisher
    }
    
    func startMonitoring() -> [Task<Void, any Error>] {
        var monitorTasks: [Task<Void, any Error>] = []
        monitorTasks.appendTask { await monitorSetUpdates() }
        monitorTasks.appendTask { await monitorCacheInvalidationTriggers() }
        monitorTasks.appendTask { await monitorSetElementUpdates() }
        return monitorTasks
    }
    
    private func monitorSetUpdates() async {
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
            
            setsUpdatedSourcePublisher(setUpdates)
            await setUpdateSequences.yield(element: setUpdates)
        }
    }
    
    private func monitorSetElementUpdates() async {
        for await setElementUpdate in setAndElementsUpdatesProvider.setElementUpdates() {
            guard !Task.isCancelled else {
                break
            }
            
            let invalidateAlbumSets = Set(setElementUpdate.map(\.ownerId))
            
            await userAlbumCache.removeElements(of: invalidateAlbumSets)
            
            setElementsUpdatedSourcePublisher(setElementUpdate)
            
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
    
    private func monitorCacheInvalidationTriggers() async {
        for await _ in await cacheInvalidationTrigger.cacheInvalidationSequence() {
            guard !Task.isCancelled else {
                break
            }
            await userAlbumCache.removeAllCachedValues()
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
