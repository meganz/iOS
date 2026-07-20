import MEGAAssets
import MEGADesignToken
import MEGAInfrastructure
import MEGAUIComponent
import SwiftUI

struct TransferQuotaHeaderView: View {
    private let header: TransferQuotaHeader

    init(header: TransferQuotaHeader) {
        self.header = header
    }

    var body: some View {
        VStack(spacing: TokenSpacing._5) {
            header.image
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
            VStack(spacing: TokenSpacing._3) {
                Text(header.title)
                    .font(.title.bold())
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                subtitleView
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var subtitleView: some View {
        var container = AttributeContainer()
        container.underlineStyle = .single
        container.font = .callout.weight(.regular)
        container.foregroundColor = TokenColors.Text.primary.swiftUI

        return AttributedTextView(
            stringAttribute: .init(
                text: header.subtitle,
                font: .callout.weight(.regular),
                foregroundColor: TokenColors.Text.primary.swiftUI
            ),
            substringAttributeList: [
                .init(
                    text: header.learnMore.text,
                    attributes: container,
                    action: { DependencyInjection.externalLinkOpener.openExternalLink(with: header.learnMore.url) }
                )
            ],
            textAlignment: .center
        )
    }
}

#Preview {
    TransferQuotaHeaderView(header: TransferQuotaHeader(
        image: MEGAAssets.Image.quotaWarning,
        title: "Transfer quota exceeded",
        subtitle: "To continue your download, upgrade your plan to get more transfer quota. Learn more.",
        learnMore: .init(text: "Learn more.", url: URL(string: "https://help.mega.io")!)
    ))
    .padding()
}
