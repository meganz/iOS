import MEGAL10n

public enum PlanSelectionSnackBarType {
    case currentRecurringPlanSelected
    
    public var title: String {
        switch self {
        case .currentRecurringPlanSelected:
            Strings.Localizable.UpgradeAccountPlan.Selection.Message.alreadyHaveRecurringSubscriptionOfPlan
        }
    }
}
