public enum RevampUpgradePlansViewType: Equatable, Sendable {
    case onboarding(isFreeAccountFirstLogin: Bool)
    case upgrade
}

extension RevampUpgradePlansViewType {
    var isOnboarding: Bool {
        if case .onboarding = self { return true }
        return false
    }
}
