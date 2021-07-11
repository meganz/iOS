import Foundation

protocol RatingRequestBaseConditionsUseCaseProtocol {
    func hasMetBaseConditions() -> Bool
    func saveLastRequestedAppVersion(_ appVersion: String)
}

struct RatingRequestBaseConditionsUseCase: RatingRequestBaseConditionsUseCaseProtocol {
    @PreferenceWrapper(key: .lastRequestedVersionForRating, defaultValue: "")
    private var lastRequestedVersion: String
    
    private let accountRepo: AccountRepositoryProtocol
    private let currentAppVersion: String

    init(preferenceUserCase: PreferenceUseCaseProtocol,
         accountRepo: AccountRepositoryProtocol,
         currentAppVersion: String) {
        self.accountRepo = accountRepo
        self.currentAppVersion = currentAppVersion
        $lastRequestedVersion.useCase = preferenceUserCase
    }
    
    func hasMetBaseConditions() -> Bool {
        currentAppVersion != lastRequestedVersion && accountRepo.totalNodesCount() >= 20
    }

    func saveLastRequestedAppVersion(_ appVersion: String) {
        lastRequestedVersion = appVersion
    }
}
