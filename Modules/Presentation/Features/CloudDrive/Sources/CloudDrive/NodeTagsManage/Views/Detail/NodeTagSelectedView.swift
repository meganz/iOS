import MEGADesignToken
import SwiftUI

struct NodeTagSelectedView: View {
    let tag: String
    @ScaledMetric private var imageSize = 20.0

    var body: some View {
        HStack(spacing: 0) {
            Image(.turquoiseCheckmark)
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .foregroundStyle(TokenColors.Icon.inverse.swiftUI)

            Text(tag)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.inverse.swiftUI)
        }
        .padding(
            EdgeInsets(top: TokenSpacing._3, leading: TokenSpacing._4, bottom: TokenSpacing._3, trailing: TokenSpacing._4)
        )
        .background(TokenColors.Components.selectionControl.swiftUI)
        .cornerRadius(TokenRadius.medium)
    }
}
