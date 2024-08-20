import MEGADomain

public enum ABTestVariant: Int, CaseIterable, Sendable {
    // ABTestVariant will be used to determine which experimental group the user is in.
    // Baseline is the control group. No changes on feature.
    // VariantA, VariantB and so on will use the new experimental versions of the feature.
    case baseline = 0, variantA, variantB
}

public enum ABTestFlagKey: ABTestFlagName, CaseIterable, Sendable {
    // This flag is not part of any existing A/B testing campaign. Only for dev testing.
    case devTest = "devtest"
    
    // This flag is part of real experiment related to the advertisement feature to know whether user will see an ad or not
    case ads = "ads"
    
    // This flag is part of real experiment related to the advertisement feature that will provide value if external ads is enabled for user.
    case externalAds = "adse"
    
    // This flag is part of real experiment related to the onboarding pro plan upselling dialog feature. Contains baseline, variantA and variantB group.
    case onboardingUpsellingDialog = "obusd"
}
