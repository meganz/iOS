import MEGADesignToken
import SwiftUI

struct NodeDescriptionFooterView: View {
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
    }

    private func view(for text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }
}
