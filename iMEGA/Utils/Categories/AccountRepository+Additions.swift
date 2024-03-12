import MEGADomain
import MEGASDKRepo

extension AccountRepository: RepositoryProtocol {
    public static var newRepo: AccountRepository {
        AccountRepository(myChatFilesFolderNodeAccess: .shared)
    }
}
