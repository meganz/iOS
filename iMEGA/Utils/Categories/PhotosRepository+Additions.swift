import MEGADomain
import MEGASDKRepo

extension PhotosRepository: SharedRepositoryProtocol {
    
    public static let sharedRepo = {
        let sdk = MEGASdk.sharedSdk
        return PhotosRepository(
            sdk: sdk,
            photoLocalSource: PhotosInMemoryCache.shared,
            nodeUpdatesProvider: NodeUpdatesProvider(sdk: sdk),
            cacheInvalidationTrigger: .init(
                logoutNotificationName: .accountDidLogout,
                didReceiveMemoryWarningNotificationName: {
                    await UIApplication.didReceiveMemoryWarningNotification
                }))
    }()
}
