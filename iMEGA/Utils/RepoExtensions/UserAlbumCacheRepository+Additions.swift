import MEGADomain
import MEGASDKRepo

extension UserAlbumCacheRepository: RepositoryProtocol {
    public static let newRepo: UserAlbumCacheRepository = {
        let userAlbumCache = UserAlbumCache.shared
        let userAlbumCacheRepositoryMonitors = UserAlbumCacheRepositoryMonitors(
            sdk: .sharedSdk,
            setAndElementsUpdatesProvider: SetAndElementUpdatesProvider(sdk: .sharedSdk),
            userAlbumCache: userAlbumCache,
            cacheInvalidationTrigger: .init(
            logoutNotificationName: .accountDidLogout,
            didReceiveMemoryWarningNotificationName: {
                await UIApplication.didReceiveMemoryWarningNotification
            })
        )
        return UserAlbumCacheRepository(
            userAlbumRepository: UserAlbumRepository.newRepo,
            userAlbumCache: userAlbumCache,
            userAlbumCacheRepositoryMonitors: userAlbumCacheRepositoryMonitors,
            albumCacheMonitorTaskManager: AlbumCacheMonitorTaskManager(
                repositoryMonitor: userAlbumCacheRepositoryMonitors)
        )
    }()
}
