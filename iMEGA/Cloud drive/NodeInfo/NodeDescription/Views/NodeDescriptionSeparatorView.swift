import MEGADesignToken
import SwiftUI

struct NodeDescriptionSeparatorView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        borderColor
            .frame(height: 0.5)
    }

    private var borderColor: Color {
        isDesignTokenEnabled
        ? TokenColors.Border.strong.swiftUI
        : colorScheme == .dark
        ? MEGAAppColor.Gray._54545865.color
        : MEGAAppColor.Gray._3C3C4330.color
    }
}
