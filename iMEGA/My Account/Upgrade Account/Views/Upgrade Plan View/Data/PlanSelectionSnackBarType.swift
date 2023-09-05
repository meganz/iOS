import MEGAL10n

enum PlanSelectionSnackBarType {
    case currentRecurringPlanSelected, none
    
    var title: String {
        switch self {
        case .currentRecurringPlanSelected:
            return Strings.Localizable.UpgradeAccountPlan.Selection.Message.alreadyHaveRecurringSubscriptionOfPlan
        default:
            return ""
        }
    }
}
