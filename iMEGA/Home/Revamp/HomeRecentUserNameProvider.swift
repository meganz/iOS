import Home
import MEGADomain

struct HomeRecentUserNameProvider: UserNameProviderProtocol {
    private let userStoreRepository: any UserStoreRepositoryProtocol
    
    init(userStoreRepository: some UserStoreRepositoryProtocol = UserStoreRepository.newRepo) {
        self.userStoreRepository = userStoreRepository
    }
    
    func displayName(for user: UserEntity) -> String? {
        userStoreRepository.getDisplayName(forUserHandle: user.handle)
    }
}
