import SwiftUI

public extension View {
    var isDesignTokenEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken)
    }
}
