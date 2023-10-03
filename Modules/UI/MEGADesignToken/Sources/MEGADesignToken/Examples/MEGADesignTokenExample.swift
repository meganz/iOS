private struct MEGADesignTokenExample {
    init() {
        // Example usage of four available generated enums
        let darkColorExample = MEGADesignTokenDarkColors.Background.backgroundBlur // UIColor
        let lightColorExample = MEGADesignTokenLightColors.Background.backgroundBlur // UIColor
        let spacingExample = MEGADesignTokenSpacing._1 // CGFloat
        let radiusExample = MEGADesignTokenRadius.small // CGFloat

        print(String(describing: darkColorExample))
        print(String(describing: lightColorExample))
        print(String(describing: spacingExample))
        print(String(describing: radiusExample))
    }
}
