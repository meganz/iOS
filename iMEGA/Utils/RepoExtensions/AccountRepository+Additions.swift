import MEGADomain
import MEGAPresentation
import MEGASDKRepo

extension AccountRepository: RepositoryProtocol {
    public static var newRepo: AccountRepository {
        AccountRepository(
            myChatFilesFolderNodeAccess: MyChatFilesFolderNodeAccess.shared,
            backupsRootFolderNodeAccess: BackupRootNodeAccess.shared,
            accountUpdatesProvider: AccountUpdatesProvider(
                sdk: MEGASdk.sharedSdk,
                areSOQBannersEnabled: {
                    DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .fullStorageOverQuotaBanner)
                }
            )
        )
    }
}
