import MEGADesignToken
import SwiftUI

struct NodeDescriptionFooterView: View {
    @Environment(\.colorScheme) private var colorScheme

    let leadingText: String?
    let trailingText: String?

    var body: some View {
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
        .padding(.vertical, 6)
        .background(backgroundColor)
    }

    private func view(for text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }

    private var backgroundColor: Color {
        isDesignTokenEnabled
        ? TokenColors.Background.page.swiftUI
        : colorScheme == .dark
        ? Color(UIColor.black1C1C1E)
        : Color(UIColor.whiteF7F7F7)
    }
}
