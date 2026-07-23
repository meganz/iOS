public enum RevampUpgradePlansViewType: Equatable, Sendable {
    case onboarding(isFreeAccountFirstLogin: Bool)
    case upgrade
}

extension RevampUpgradePlansViewType {
    /// Onboarding shows the "Maybe later" dismiss control; upgrade shows the close button.
    var usesMaybeLaterButton: Bool {
        if case .onboarding = self { return true }
        return false
    }
}
