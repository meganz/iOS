import MEGADesignToken
import MEGAL10n
import SwiftUI

struct MoreTileView: View {
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Text(Strings.Localizable.more)
                .font(.callout)
                .fontWeight(.semibold)
                .underline()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundStyle(TokenColors.Text.accent.swiftUI)
                .frame(
                    width: LeftOffItemWidgetCardView.Layout.moreTileWidth,
                    height: LeftOffItemWidgetCardView.Layout.previewHeight
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MoreTileView {}
}
