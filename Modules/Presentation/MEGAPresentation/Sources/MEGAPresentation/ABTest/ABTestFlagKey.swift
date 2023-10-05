import MEGADomain

public enum ABTestVariant: Int, CaseIterable, Sendable {
    // ABTestVariant will be used to determine which experimental group the user is in.
    // Baseline is the control group. No changes on feature.
    // VariantA, VariantB and so on will use the new experimental versions of the feature.
    case baseline = 0, variantA, variantB
}

public enum ABTestFlagKey: ABTestFlagName, Sendable {
    // This flag is not part of any existing A/B testing campaign. Only for dev testing.
    case devTest = "devtest"
    
    // This flag is part of real experiment related to Upgrade account screen
    // Criteria: Every day 25% of users will be assigned to see either UpgradeTableViewController(current UI) or UpgradeAccountPlanView(new UI) (12.5% each respectively)
    case upgradePlanRevamp = "sus2023"

    // This flag is part of real experiment related to the new search improvements on Home screen
    case newSearch = "ab_nsf"
}
