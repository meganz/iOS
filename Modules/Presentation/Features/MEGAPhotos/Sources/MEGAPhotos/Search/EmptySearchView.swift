import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct EmptySearchView: View {
    var body: some View {
        ContentUnavailableView {
            Image(uiImage: MEGAAssetsImageProvider.image(named: "search2") ?? UIImage())
        } description: {
            Text(Strings.Localizable.Photos.SearchHistory.Empty.description)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    EmptySearchView()
}
