import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct PDFThumbnailsToggleView: View {
    let isActive: Bool
    let action: () -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var dimension: CGFloat {
        verticalSizeClass == .compact ? 32 : 40
    }

    var body: some View {
        Button(action: action) {
            MEGAAssets.Image.squares9
                .renderingMode(.template)
                .foregroundStyle(
                    isActive
                        ? TokenColors.Icon.inverseAccent.swiftUI
                        : TokenColors.Icon.primary.swiftUI
                )
                .frame(width: dimension, height: dimension)
                .background(
                    isActive ? TokenColors.Icon.accent.swiftUI : .clear,
                    in: Circle()
                )
        }
        .accessibilityLabel(Strings.Localizable.thumbnailView)
    }
}
