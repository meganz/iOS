import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

struct PSAContentView: View {
    let entity: PSAEntity

    let onPrimaryAction: () -> Void
    let onSecondaryAction: (() -> Void)?

    private let imageSize: CGFloat = 48
    private let cardCornerRadius: CGFloat = 26
    private let buttonCornerRadius: CGFloat = 8
    @ScaledMetric private var titleFontSize: CGFloat = 15
    @ScaledMetric private var descriptionFontSize: CGFloat = 12
    private let outerHorizontalMargin: CGFloat = 16
    private let outerBottomMargin: CGFloat = 8
    private let innerContentPadding: CGFloat = 10
    private let imageTextSpacing: CGFloat = 10
    private let textStackSpacing: CGFloat = 8
    private let buttonStackSpacing: CGFloat = 12
    private let buttonFontSize: CGFloat = 14
    private let buttonHorizontalPadding: CGFloat = 16
    private let buttonHeight: CGFloat = 44
    private let buttonStackTopPadding: CGFloat = 12
    private let borderLineWidth: CGFloat = 1

    private var hasPositive: Bool {
        entity.positiveText != nil && entity.positiveLink != nil
    }

    private var primaryTitle: String {
        guard hasPositive, let positiveText = entity.positiveText else {
            return Strings.Localizable.dismiss
        }
        return positiveText
    }
    
    private var imageURL: URL? {
        guard let urlString = entity.imageURL else { return nil }
        return URL(string: urlString)
    }

    private var hasImage: Bool {
        imageURL != nil
    }

    private var leftButtonBackground: UIColor {
        hasPositive ? TokenColors.Button.primary : TokenColors.Button.secondary
    }

    private var leftButtonTitleColor: UIColor {
        hasPositive ? TokenColors.Text.inverseAccent : TokenColors.Text.accent
    }

    private var rightButtonBackground: UIColor {
        TokenColors.Button.secondary
    }

    private var rightButtonTitleColor: UIColor {
        TokenColors.Text.accent
    }
    
    private var imageView: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure, .empty:
                        Color.clear
                    @unknown default:
                        Color.clear
                    }
                }
            }
        }
        .frame(width: imageSize, height: imageSize)
        .clipShape(Circle())
    }

    var body: some View {
        if #available(iOS 26.0, *), DIContainer.featureFlagProvider.isLiquidGlassEnabled() {
            content
                .padding(innerContentPadding)   // horizontal/vertical padding inside content
                .glassEffect(.regular, in: .rect(cornerRadius: cardCornerRadius, style: .continuous))
                .padding(EdgeInsets(top: 0, leading: outerHorizontalMargin, bottom: outerBottomMargin, trailing: outerHorizontalMargin))   // margin outside of content
        } else {
            content
                .padding(innerContentPadding)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
                .padding(EdgeInsets(top: 0, leading: outerHorizontalMargin, bottom: outerBottomMargin, trailing: outerHorizontalMargin))
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: imageTextSpacing) {
            if hasImage { imageView }

            VStack(alignment: .leading, spacing: textStackSpacing) {
                Text(entity.title ?? "")
                    .font(.system(size: titleFontSize))

                Text(entity.description ?? "")
                    .font(.system(size: descriptionFontSize))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: buttonStackSpacing) {
                    actionButton(title: primaryTitle,
                                 background: leftButtonBackground,
                                 titleColor: leftButtonTitleColor) {
                        onPrimaryAction()
                    }

                    if hasPositive, let onSecondaryAction {
                        actionButton(title: Strings.Localizable.dismiss,
                                     background: rightButtonBackground,
                                     titleColor: rightButtonTitleColor) {
                            onSecondaryAction()
                        }
                    }
                }
                .padding(.top, buttonStackTopPadding)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func actionButton(
        title: String,
        background: UIColor,
        titleColor: UIColor,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
        .font(.system(size: buttonFontSize, weight: .semibold))
        .padding(.horizontal, buttonHorizontalPadding)
        .frame(height: buttonHeight)
        .background(Color(background))
        .foregroundStyle(Color(titleColor))
        .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius, style: .continuous))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
            .fill(Color(TokenColors.Background.surface1))

            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .stroke(Color(TokenColors.Border.strong), lineWidth: borderLineWidth)
            )
    }
}
