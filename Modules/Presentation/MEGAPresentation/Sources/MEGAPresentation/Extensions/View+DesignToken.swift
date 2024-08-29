import SwiftUI

public extension View {
    var isDesignTokenEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
    }
}

public func designTokenEnabled() -> Bool {
    DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
}
