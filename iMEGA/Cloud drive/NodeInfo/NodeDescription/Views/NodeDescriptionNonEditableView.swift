import MEGADesignToken
import SwiftUI

struct NodeDescriptionNonEditableView: View {
    @Environment(\.colorScheme) var colorScheme

    private let description: NodeDescriptionViewModel.Description
    private let verticalPadding: CGFloat?

    init(description: NodeDescriptionViewModel.Description, verticalPadding: CGFloat? = nil) {
        self.description = description
        self.verticalPadding = verticalPadding
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(description.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.body)
                .foregroundStyle(
                    isDesignTokenEnabled
                    ? description.isPlaceholder ? TokenColors.Text.secondary.swiftUI : TokenColors.Text.primary.swiftUI
                    : description.isPlaceholder ? Color(UIColor.secondaryLabel) : Color(UIColor.label)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, verticalPadding)
            NodeDescriptionSeparatorView()
        }
        .background(
            isDesignTokenEnabled
            ? TokenColors.Background.page.swiftUI
            : colorScheme == .dark
            ? Color(UIColor.black2C2C2E)
            : Color(UIColor.whiteFFFFFF)
        )
    }
}
