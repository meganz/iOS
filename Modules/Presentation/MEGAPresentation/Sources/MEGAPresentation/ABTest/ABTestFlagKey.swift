import MEGADomain

public enum ABTestVariant: Int, CaseIterable {
    case baseline = 0, variantA, variantB
}

public enum ABTestFlagKey: ABTestFlagName {
    // This flag is not part of any existing A/B testing campaign. Only for dev testing.
    case devTest = "devtest"
}
