import MEGAAppSDKRepo
import MEGADomain

extension PhotosRepository: @retroactive SharedRepositoryProtocol {
    
    public static let sharedRepo = {
        let sdk = MEGASdk.sharedSdk
        let localSource = PhotosInMemoryCache.shared
        return PhotosRepository(
            sdk: sdk,
            photoLocalSource: localSource,
            photosRepositoryTaskManager: PhotosRepositoryTaskManager(
                photoLocalSource: localSource,
                photoCacheRepositoryMonitors: PhotoCacheRepositoryMonitors(
                    sdk: sdk,
                    nodeUpdatesProvider: NodeUpdatesProvider(sdk: sdk),
                    photoLocalSource: localSource,
                    cacheInvalidationTrigger: .init(
                        logoutNotificationName: .accountDidLogout,
                        didReceiveMemoryWarningNotificationName: {
                            UIApplication.didReceiveMemoryWarningNotification
                        })))
        )
    }()
}
