import MEGADomain
import MEGASDKRepo

extension UserAlbumCacheRepository: @retroactive RepositoryProtocol {
    public static let newRepo: UserAlbumCacheRepository = {
        let userAlbumCache = UserAlbumCache.shared
        let userAlbumCacheRepositoryMonitors = UserAlbumCacheRepositoryMonitors(
            sdk: .sharedSdk,
            setAndElementsUpdatesProvider: SetAndElementUpdatesProvider(sdk: .sharedSdk),
            userAlbumCache: userAlbumCache,
            cacheInvalidationTrigger: .init(
            logoutNotificationName: .accountDidLogout,
            didReceiveMemoryWarningNotificationName: {
                UIApplication.didReceiveMemoryWarningNotification
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
