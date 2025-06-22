import MEGAL10n
import MEGAUIComponent

public struct PlanBadge: Equatable {
    public let type: MEGABadgeType
    public let text: String
    
    public init(type: MEGABadgeType, text: String) {
        self.type = type
        self.text = text
    }
}

public extension PlanBadge {
    static var currentPlan: PlanBadge {
        PlanBadge(
            type: .warning,
            text: Strings.Localizable.UpgradeAccountPlan.Plan.Tag.currentPlan
        )
    }

    static var recommended: PlanBadge {
        PlanBadge(
            type: .infoPrimary,
            text: Strings.Localizable.UpgradeAccountPlan.Plan.Tag.recommended
        )
    }
}
