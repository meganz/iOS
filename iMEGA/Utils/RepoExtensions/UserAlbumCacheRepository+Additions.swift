import MEGADomain
import MEGASDKRepo

extension UserAlbumCacheRepository: RepositoryProtocol {
    public static let newRepo: UserAlbumCacheRepository = UserAlbumCacheRepository(
        userAlbumRepository: UserAlbumRepository.newRepo,
        userAlbumCache: UserAlbumCache.shared,
        setAndElementsUpdatesProvider: SetAndElementUpdatesProvider(sdk: .sharedSdk),
        cacheInvalidationTrigger: .init(
            logoutNotificationName: .accountDidLogout,
            didReceiveMemoryWarningNotificationName: {
                await UIApplication.didReceiveMemoryWarningNotification
            }))
}
