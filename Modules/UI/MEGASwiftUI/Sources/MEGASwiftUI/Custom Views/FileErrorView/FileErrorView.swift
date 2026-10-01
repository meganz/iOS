import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

public struct FileErrorView: View {
    private let icon: Image
    private let title: String
    private let message: String
    private let retryTitle: String
    private let onRetry: () -> Void

    public init(
        icon: Image = MEGAAssets.Image.glassErrorIcon,
        title: String = Strings.Localizable.General.Preview.Error.title,
        message: String = Strings.Localizable.General.Preview.Error.message,
        retryTitle: String = Strings.Localizable.General.Button.tryAgain,
        onRetry: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.onRetry = onRetry
    }

    public var body: some View {
        VStack(spacing: TokenSpacing._7) {
            icon
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityHidden(true)

            VStack(spacing: TokenSpacing._5) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, TokenSpacing._5)

            retryButtonMultilineContentHugging
        }
        .padding(.horizontal, TokenSpacing._5)
        .scrollableWhenTallerThanContainer()
    }

    // MARK: Retry button

    private var retryButtonMultilineContentHugging: some View {
        ViewThatFits(in: .horizontal) {
            // `.fixedSize(horizontal: true, ...)` lets the `retryButton` hug
            // short content.
            // - The `.frame(maxWidth: .infinity, ...)` call in
            //   `MEGAButtonStyle.label` forces even buttons with short content
            //   to expand to parent width. `.fixedSize` overrides that effect.
            // However, for long content, this modifier prevents the content
            // from wrapping to the next line, and instead layouts the long text
            // in a single line flowing beyond screen edges.
            //
            // Adding a sibling without the modifier inside `ViewThatFits`
            // covers both cases:
            // - Short content -> `ViewThatFits` picks the version with the
            //                    modifier.
            // - Long content -> `ViewThatFits` picks the version without
            //                   the modifier, which lets the text content
            //                   show in multiple lines.
            retryButton
                .fixedSize(horizontal: true, vertical: false)
            retryButton
        }
    }

    private var retryButton: some View {
        MEGAButton(
            retryTitle,
            type: .secondary,
            action: onRetry
        )
    }
}

#Preview("Defaults") {
    FileErrorView()
}

#Preview("Custom Content") {
    FileErrorView(
        icon: MEGAAssets.Image.transferError,
        title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
        message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua",
        retryTitle: "Very very long button title: Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"
    )
}

#Preview("Large Dynamic Type Text", traits: .landscapeLeft) {
    FileErrorView()
        .environment(\.dynamicTypeSize, .accessibility5)
}
