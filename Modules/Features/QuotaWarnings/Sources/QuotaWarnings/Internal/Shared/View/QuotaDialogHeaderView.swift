import MEGAAssets
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct QuotaDialogHeaderView: View {
    private let header: QuotaDialogHeader

    init(header: QuotaDialogHeader) {
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

    @ViewBuilder private var subtitleView: some View {
        switch header.subtitle {
        case .plain(let text):
            Text(text)
                .font(.callout.weight(.regular))
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        case .attributed(let text, let links):
            AttributedTextView(
                stringAttribute: .init(
                    text: text,
                    font: .callout.weight(.regular),
                    foregroundColor: TokenColors.Text.primary.swiftUI
                ),
                substringAttributeList: links,
                textAlignment: .center
            )
        }
    }
}

#Preview("Plain") {
    QuotaDialogHeaderView(header: QuotaDialogHeader(
        image: MEGAAssets.Image.quotaWarning,
        title: "Your storage is 90% full",
        subtitle: .plain("Upgrade your plan before you run out of space")
    ))
    .padding()
}

#Preview("Attributed") {
    QuotaDialogHeaderView(header: QuotaDialogHeader(
        image: MEGAAssets.Image.quotaWarning,
        title: "Transfer quota exceeded",
        subtitle: .attributed(
            text: "To continue your download, upgrade your plan to get more transfer quota. Learn more.",
            links: [.init(text: "Learn more.", font: .callout.weight(.regular))]
        )
    ))
    .padding()
}
