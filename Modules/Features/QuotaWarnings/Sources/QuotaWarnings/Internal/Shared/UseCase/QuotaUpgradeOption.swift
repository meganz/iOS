import MEGADomain

enum QuotaUpgradeOption: Sendable {
    case available(accountDetails: AccountDetailsEntity, plan: PlanEntity)
    case unavailable(accountDetails: AccountDetailsEntity)
}
