import MEGAAppSDKRepo
import MEGADomain
import MEGAPreference

@MainActor
final class UpgradeEncouragementViewModel {
    
    private enum Constants {
        static let minDaysToEncourageToUpgrade = 3
    }
    
    @PreferenceWrapper(key: PreferenceKeyEntity.lastEncourageUpgradeDate, defaultValue: nil)
    private var lastEncourageUpgradeDate: Date?

    private let showTimeTracker: any UpgradeEncouragementShowTimeTracking
    private let accountUseCase: any AccountUseCaseProtocol
    private let router: any UpgradeSubscriptionRouting
    private let randomNumberGenerator: any RandomNumberGenerating
    private let calendar: Calendar
    
    init(
        showTimeTracker: some UpgradeEncouragementShowTimeTracking = UpgradeEncouragementShowTimeTracker(),
        accountUseCase: some AccountUseCaseProtocol = AccountUseCase(repository: AccountRepository.newRepo),
        router: some UpgradeSubscriptionRouting,
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        randomNumberGenerator: some RandomNumberGenerating = RandomNumberGenerator(),
        calendar: Calendar = .current
    ) {
        self.showTimeTracker = showTimeTracker
        self.accountUseCase = accountUseCase
        self.router = router
        self.randomNumberGenerator = randomNumberGenerator
        self.calendar = calendar
        $lastEncourageUpgradeDate.useCase = preferenceUseCase
    }
    
    private var isFreeAccount: Bool {
        accountUseCase.currentAccountDetails?.proLevel == .free
    }
    
    func encourageUpgradeIfNeeded() {
        // Only shows encouragement if it has not been shown and account not pro
        guard !showTimeTracker.alreadyPresented, isFreeAccount else { return }
        
        guard let daysSinceAccountCreation, daysSinceAccountCreation > Constants.minDaysToEncourageToUpgrade,
              // Randomly go through 5% of the time
              randomNumberGenerator.generate(lowerBound: 1, upperBound: 20) == 1  else { return }
        
        // Don't show encouragement if it was shown within one week
        if let weeksSincePreviousEncouragement, weeksSincePreviousEncouragement < 1 { return }
        
        router.showUpgradeAccount()
        lastEncourageUpgradeDate = Date()
        showTimeTracker.alreadyPresented = true
    }
    
    // Private methods
    private var daysSinceAccountCreation: Int? {
        guard let accountCreationDate = accountUseCase.accountCreationDate else { return nil }
        let components = calendar.dateComponents([.day], from: accountCreationDate, to: Date())
        return components.day
    }
    
    private var weeksSincePreviousEncouragement: Int? {
        guard let lastEncourageUpgradeDate else { return nil }
        let components = calendar.dateComponents([.weekOfYear], from: lastEncourageUpgradeDate, to: Date())
        return components.weekOfYear
    }
}
