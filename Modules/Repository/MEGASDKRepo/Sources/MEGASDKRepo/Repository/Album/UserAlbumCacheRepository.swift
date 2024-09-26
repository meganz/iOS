import Combine
import Foundation
import MEGADomain
import MEGASwift

final public class UserAlbumCacheRepository: UserAlbumRepositoryProtocol {
    public var setsUpdatedPublisher: AnyPublisher<[SetEntity], Never> {
        userAlbumCacheRepositoryMonitors.setsUpdatedPublisher
    }
    public var setElementsUpdatedPublisher: AnyPublisher<[SetElementEntity], Never> {
        userAlbumCacheRepositoryMonitors.setElementsUpdatedPublisher
    }
    
    private let userAlbumRepository: any UserAlbumRepositoryProtocol
    private let userAlbumCache: any UserAlbumCacheProtocol
    private let userAlbumCacheRepositoryMonitors: any UserAlbumCacheRepositoryMonitorsProtocol
    private let albumCacheMonitorTaskManager: any AlbumCacheMonitorTaskManagerProtocol
    
    public init(
        userAlbumRepository: some UserAlbumRepositoryProtocol,
        userAlbumCache: some UserAlbumCacheProtocol,
        userAlbumCacheRepositoryMonitors: some UserAlbumCacheRepositoryMonitorsProtocol,
        albumCacheMonitorTaskManager: some AlbumCacheMonitorTaskManagerProtocol
    ) {
        self.userAlbumRepository = userAlbumRepository
        self.userAlbumCache = userAlbumCache
        self.userAlbumCacheRepositoryMonitors = userAlbumCacheRepositoryMonitors
        self.albumCacheMonitorTaskManager = albumCacheMonitorTaskManager
    }
    
    public func albums() async -> [SetEntity] {
        await updateAlbumsMonitoring()
        
        let cachedAlbums = await userAlbumCache.albums
        guard cachedAlbums.isEmpty else {
            return cachedAlbums
        }
        let userAlbums = await userAlbumRepository.albums()
        await userAlbumCache.setAlbums(userAlbums)
        return userAlbums
    }
    
    /// AnyAsyncSequence that produces a new list of SetEntity when a change has occurred on any given UserAlbum SetEntity for this users account
    /// - Returns: AnyAsyncSequence<[SetEntity]> of all the available Albums, only yields when a new update has occurred.
    public func albumsUpdated() async -> AnyAsyncSequence<[SetEntity]> {
        await updateAlbumsMonitoring()
        
        return await userAlbumCacheRepositoryMonitors.setUpdateAsyncSequences
            .compactMap { [weak self] _ in await self?.albums() }
            .eraseToAnyAsyncSequence()
    }
    
    /// AsyncSequence that will yield a new SetEntity, iff the provided id matches an updated SetEntity handle. If the provided id does not match then it will not yield any value even on changes to other Sets.
    /// - Parameter id: HandleEntity for a given set. This will be used to filter results from Set Changes
    /// - Returns: AnyAsyncSequence<SetEntity> of all the available Albums, only yields when a new update has occurred for the provided SetEntity Id. If the yielded results is nil, this means that the Set has been removed and no longer available.
    public func albumUpdated(by id: HandleEntity) async -> AnyAsyncSequence<SetEntity?> {
        await updateAlbumsMonitoring()
        
        return await userAlbumCacheRepositoryMonitors.setUpdateAsyncSequences
            .compactMap { $0.first { setEntity in setEntity.handle == id }}
            .map({ [weak self] updatedSet -> SetEntity? in
                guard let self else {
                    return nil
                }
                
                return if updatedSet.changeTypes.contains(.removed) {
                    nil
                } else {
                    await userAlbumCache.album(forHandle: id)
                }
            })
            .eraseToAnyAsyncSequence()
    }
    
    public func albumContentUpdated(by id: HandleEntity) async -> AnyAsyncSequence<[SetElementEntity]> {
        await updateAlbumsMonitoring()
        
        return await userAlbumCacheRepositoryMonitors.setElementUpdateAsyncSequences
            .map {
                $0.filter { $0.ownerId == id }
            }
            .filter { $0.isNotEmpty }
            .eraseToAnyAsyncSequence()
    }
    
    /// AsyncSequence that will yield a new list of SetElementEntities when the provided Set Id has had an update to its elements. The id will used to filter the results from all SetElement updates to only yeild on this specific sets changes. This yields only when changes to Sets elements occur.
    /// It will yield the latest list of SetElementEntities, after a change has occurred.
    /// - Parameters:
    /// - Parameter id: HandleEntity for a given set. This will be used to filter results from SetElement Changes.
    ///   - includeElementsInRubbishBin:  Boolean indicating if elements in the rubbish bin should be included in the yielded value.
    /// - Returns: AnyAsyncSequence<[SetElementEntity]> of all the Album Elements, it only yields when a new update has occurred in  the provided SetEntity Id.
    public func albumContentUpdated(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> AnyAsyncSequence<[SetElementEntity]> {
        await updateAlbumsMonitoring()
        
        return await userAlbumCacheRepositoryMonitors.setElementUpdateOnSetsAsyncSequences
            .compactMap({ [weak self] updatedSets -> [SetElementEntity]? in
                guard
                    let self,
                    updatedSets.contains(where: { $0.handle == id }) else {
                    return nil
                }
                return await albumContent(by: id, includeElementsInRubbishBin: includeElementsInRubbishBin)
            })
            .eraseToAnyAsyncSequence()
    }
    
    public func albumContent(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [SetElementEntity] {
        await userAlbumRepository.albumContent(by: id, includeElementsInRubbishBin: includeElementsInRubbishBin)
    }
    
    public func albumElement(by id: HandleEntity, elementId: HandleEntity) async -> SetElementEntity? {
        await userAlbumRepository.albumElement(by: id, elementId: elementId)
    }
    
    public func albumElementIds(by id: HandleEntity, includeElementsInRubbishBin: Bool) async -> [AlbumPhotoIdEntity] {
        await updateAlbumsMonitoring()
        
        if let cachedAlbumElementIds = await userAlbumCache.albumElementIds(forAlbumId: id),
           cachedAlbumElementIds.isNotEmpty {
            return cachedAlbumElementIds
        }
        let albumElementIds = await userAlbumRepository.albumElementIds(
            by: id, includeElementsInRubbishBin: includeElementsInRubbishBin)
        await userAlbumCache.setAlbumElementIds(forAlbumId: id, elementIds: albumElementIds)
        return albumElementIds
    }
    
    public func albumElementId(by id: HandleEntity, elementId: HandleEntity) async -> AlbumPhotoIdEntity? {
        // Load all album element ids to avoid setting the cache to only a single item for the album
        await albumElementIds(by: id, includeElementsInRubbishBin: false)
            .first(where: { $0.id == elementId })
    }
    
    public func createAlbum(_ name: String?) async throws -> SetEntity {
        try await userAlbumRepository.createAlbum(name)
    }
    
    public func updateAlbumName(_ name: String, _ id: HandleEntity) async throws -> String {
        try await userAlbumRepository.updateAlbumName(name, id)
    }
    
    public func deleteAlbum(by id: HandleEntity) async throws -> HandleEntity {
        try await userAlbumRepository.deleteAlbum(by: id)
    }
    
    public func addPhotosToAlbum(by id: HandleEntity, nodes: [NodeEntity]) async throws -> AlbumElementsResultEntity {
        try await userAlbumRepository.addPhotosToAlbum(by: id, nodes: nodes)
    }
    
    public func updateAlbumElementName(albumId: HandleEntity, elementId: HandleEntity, name: String) async throws -> String {
        try await userAlbumRepository.updateAlbumElementName(albumId: albumId, elementId: elementId, name: name)
    }
    
    public func updateAlbumElementOrder(albumId: HandleEntity, elementId: HandleEntity, order: Int64) async throws -> Int64 {
        try await userAlbumRepository.updateAlbumElementOrder(albumId: albumId, elementId: elementId, order: order)
    }
    
    public func deleteAlbumElements(albumId: HandleEntity, elementIds: [HandleEntity]) async throws -> AlbumElementsResultEntity {
        try await userAlbumRepository.deleteAlbumElements(albumId: albumId, elementIds: elementIds)
    }
    
    public func updateAlbumCover(for albumId: HandleEntity, elementId: HandleEntity) async throws -> HandleEntity {
        try await userAlbumRepository.updateAlbumCover(for: albumId, elementId: elementId)
    }
    
    /// Unsure that cache is primed and background monitoring is running.
    private func updateAlbumsMonitoring() async {
        await ensureCacheIsPrimedAfterInvalidation()
        await ensureAlbumUpdateBackgroundMonitoring()
    }
    
    /// Monitor album updates will ensure that the tasks are still running in the background. If a child task is stopped all tasks will be stopped and cache will be re-primed
    /// and monitoring will be restarted to avoid stale data.
    private func ensureAlbumUpdateBackgroundMonitoring() async {
        guard await didMonitoringTaskStop() else { return }
        
        await albumCacheMonitorTaskManager.stopMonitoring()
        await primeCaches()
        await albumCacheMonitorTaskManager.startMonitoring()
    }
    
    private func ensureCacheIsPrimedAfterInvalidation() async {
        guard await userAlbumCache.wasForcedCleared else { return }
        
        if await !didMonitoringTaskStop() {
            await primeCaches()
        }
        await userAlbumCache.clearForcedFlag()
    }
    
    private func primeCaches() async {
        await userAlbumCache.removeAllCachedValues(forced: false)
        
        let userAlbums = await userAlbumRepository.albums()
        await userAlbumCache.setAlbums(userAlbums)
        
        await withTaskGroup(of: Void.self) { group in
            userAlbums.forEach { album in
                group.addTask {
                    let albumElementIds = await self.userAlbumRepository.albumElementIds(
                        by: album.id.handle, includeElementsInRubbishBin: false)
                    await self.userAlbumCache.setAlbumElementIds(forAlbumId: album.id.handle, elementIds: albumElementIds)
                }
            }
        }
    }
    
    private func didMonitoringTaskStop() async -> Bool {
        await albumCacheMonitorTaskManager.didChildTaskStop()
    }
}
