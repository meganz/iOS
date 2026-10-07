import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct LeftOffItemsWidgetEmptyView: View {
    var body: some View {
        HStack(spacing: TokenSpacing._5) {
            Text(Strings.Localizable.ContinueWhereYouLeftOff.Empty.message)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)

            MEGAAssets.Image.continueWhereYouLeftIcon
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
        }
        .padding(.leading, TokenSpacing._5)
        .padding(.trailing, TokenSpacing._4)
        .frame(minHeight: TokenSpacing._16)
    }
}

#Preview {
    LeftOffItemsWidgetEmptyView()
}
