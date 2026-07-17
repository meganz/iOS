public enum RevampUpgradePlansViewType: Equatable, Sendable {
    case onboarding(isFreeAccountFirstLogin: Bool)
    case upgrade
}
