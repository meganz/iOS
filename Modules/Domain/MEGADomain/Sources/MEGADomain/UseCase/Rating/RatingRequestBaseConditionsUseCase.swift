import MEGAPreference

public protocol RatingRequestBaseConditionsUseCaseProtocol {
    func hasMetBaseConditions() -> Bool
    func saveLastRequestedAppVersion(_ appVersion: String)
}

public struct RatingRequestBaseConditionsUseCase<T: PreferenceUseCaseProtocol, U: AccountRepositoryProtocol>: RatingRequestBaseConditionsUseCaseProtocol {
    @PreferenceWrapper(key: PreferenceKeyEntity.lastRequestedVersionForRating, defaultValue: "")
    private var lastRequestedVersion: String
    
    private let accountRepo: U
    private let currentAppVersion: String

    public init(
        preferenceUserCase: T,
        accountRepo: U,
        currentAppVersion: String
    ) {
        self.accountRepo = accountRepo
        self.currentAppVersion = currentAppVersion
        $lastRequestedVersion.useCase = preferenceUserCase
    }
    
    public func hasMetBaseConditions() -> Bool {
        currentAppVersion != lastRequestedVersion && accountRepo.totalNodesCount() >= 20
    }

    public func saveLastRequestedAppVersion(_ appVersion: String) {
        lastRequestedVersion = appVersion
    }
}
