import MEGAL10n

public enum PlanSelectionSnackBarType {
    case currentRecurringPlanSelected, none
    
    public var title: String {
        switch self {
        case .currentRecurringPlanSelected:
            return Strings.Localizable.UpgradeAccountPlan.Selection.Message.alreadyHaveRecurringSubscriptionOfPlan
        default:
            return ""
        }
    }
}
