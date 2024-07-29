import MEGADesignToken
import SwiftUI

struct NodeDescriptionFooterView: View {
    @Environment(\.colorScheme) var colorScheme

    let leadingText: String?
    let trailingText: String?

    var body: some View {
        VStack {
            borderColor
                .frame(height: 0.5)

            HStack {
                if let leadingText {
                    view(for: leadingText)
                }
                Spacer()
                if let trailingText {
                    view(for: trailingText)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func view(for text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }

    private var borderColor: Color {
        isDesignTokenEnabled
        ? TokenColors.Border.strong.swiftUI
        : colorScheme == .dark
        ? MEGAAppColor.Gray._54545865.color
        : MEGAAppColor.Gray._3C3C4330.color
    }
}
