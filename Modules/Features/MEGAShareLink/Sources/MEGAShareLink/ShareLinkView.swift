import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

public struct ShareLinkView: View {
    @Environment(\.dismiss) private var dismiss
    private let nodes: [NodeEntity]

    public init(nodes: [NodeEntity]) {
        self.nodes = nodes
    }

    public var body: some View {
        TokenColors.Background.page.swiftUI
            .ignoresSafeArea()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    closeButton
                }
            }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            closeIcon
        }
        .accessibilityLabel(Strings.Localizable.close)
    }

    @ViewBuilder
    private var closeIcon: some View {
        let icon = MEGAAssets.Image.x
            .frame(width: TokenSpacing._7, height: TokenSpacing._7)
            .foregroundStyle(TokenColors.Icon.primary.swiftUI)

        // From iOS 26 the toolbar gives the icon a tappable glass capsule of
        // its own, so the padding would double up.
        if #available(iOS 26.0, *) {
            icon
        } else {
            icon.padding(10)
        }
    }
}
