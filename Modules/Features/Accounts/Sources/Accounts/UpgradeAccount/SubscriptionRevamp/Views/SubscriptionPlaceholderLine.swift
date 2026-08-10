import MEGADesignToken
import SwiftUI

/// A single stand-in text line in the subscription skeletons. Shimmering is applied by the group it sits in.
struct SubscriptionPlaceholderLine: View {
    var body: some View {
        Capsule()
            .fill(SubscriptionPlaceholder.color)
            .frame(height: 16)
    }
}

enum SubscriptionPlaceholder {
    static var color: Color {
        TokenColors.Text.primary.swiftUI
    }
}
