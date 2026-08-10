import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

/// Shimmering skeleton shown while the node behind the file link is being resolved.
/// It mimics the preview and the name/size lines that replace it once the node is known.
struct FileLinkLoadingView: View {
    private enum Constants {
        static let previewHeight: CGFloat = 298
        static let nameWidth: CGFloat = 165
        static let nameHeight: CGFloat = 22
        static let sizeWidth: CGFloat = 110
        static let sizeHeight: CGFloat = 18
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._9) {
            bone(height: Constants.previewHeight, cornerRadius: TokenRadius.large)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: TokenSpacing._1) {
                bone(width: Constants.nameWidth, height: Constants.nameHeight)
                bone(width: Constants.sizeWidth, height: Constants.sizeHeight)
            }
        }
        .padding(TokenSpacing._5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .shimmering()
        .allowsHitTesting(false)
        // The bones carry no meaning of their own, so collapse them into a single
        // element that announces the loading state the skeleton stands in for.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.Localizable.loading)
    }

    private func bone(
        width: CGFloat? = nil,
        height: CGFloat,
        cornerRadius: CGFloat = TokenRadius.medium
    ) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(TokenColors.Text.primary.swiftUI)
            .frame(width: width, height: height)
    }
}

#Preview {
    FileLinkLoadingView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.page.swiftUI)
}
