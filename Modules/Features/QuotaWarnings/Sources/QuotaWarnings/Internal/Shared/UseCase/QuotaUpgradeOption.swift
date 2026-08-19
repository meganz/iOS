import MEGADomain

enum QuotaUpgradeOption: Sendable {
    case available(accountDetails: AccountDetailsEntity, recommendedPlan: RecommendedUpgradePlanEntity)
    case unavailable(accountDetails: AccountDetailsEntity)
    case signIn(recommendedPlan: RecommendedUpgradePlanEntity)
}
