import MEGADesignToken
import SwiftUI

struct NodeDescriptionSeparatorView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        borderColor
            .frame(height: 1)
    }

    private var borderColor: Color {
        isDesignTokenEnabled
        ? TokenColors.Border.strong.swiftUI
        : colorScheme == .dark
        ? Color(UIColor.gray54545865)
        : Color(UIColor.gray3C3C4330)
    }
}
