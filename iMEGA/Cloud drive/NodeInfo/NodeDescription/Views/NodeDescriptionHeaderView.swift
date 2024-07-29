import MEGADesignToken
import SwiftUI

struct NodeDescriptionHeaderView: View {
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
}
