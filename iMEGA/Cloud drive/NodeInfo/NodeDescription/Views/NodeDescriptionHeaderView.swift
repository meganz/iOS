import MEGADesignToken
import SwiftUI

struct NodeDescriptionHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String

    var body: some View {
        VStack {
            Text(title)
                .font(.footnote)
                .foregroundStyle(titleColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            borderColor
                .frame(height: 0.5)
        }
        .padding(.top, 30)
        .background(backgroundColor)
    }

    private var titleColor: Color {
        isDesignTokenEnabled
        ? TokenColors.Text.secondary.swiftUI
        : .primary
    }

    private var borderColor: Color {
        isDesignTokenEnabled
        ? TokenColors.Border.strong.swiftUI
        : .clear
    }

    private var backgroundColor: Color {
        isDesignTokenEnabled
        ? TokenColors.Background.page.swiftUI
        : colorScheme == .dark
        ? Color(UIColor.black1C1C1E)
        : Color(UIColor.whiteF7F7F7)
    }
}
