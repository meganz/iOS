import MEGADesignToken
import SwiftUI

struct NodeDescriptionNonEditableView: View {
    private let description: String
    private let verticalPadding: CGFloat?

    init(description: String, verticalPadding: CGFloat? = nil) {
        self.description = description
        self.verticalPadding = verticalPadding
    }

    var body: some View {
        Text(description)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.body)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .padding(.horizontal, 16)
            .padding(.vertical, verticalPadding)
    }
}
