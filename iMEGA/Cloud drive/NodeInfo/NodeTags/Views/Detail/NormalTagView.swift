import MEGADesignToken
import SwiftUI

struct NormalTagView: View {
    let tag: String

    var body: some View {
        Text(tag)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .padding(
                EdgeInsets(top: TokenSpacing._3, leading: TokenSpacing._4, bottom: TokenSpacing._3, trailing: TokenSpacing._4)
            )
            .background(TokenColors.Button.secondary.swiftUI)
            .cornerRadius(TokenRadius.medium)
    }
}
