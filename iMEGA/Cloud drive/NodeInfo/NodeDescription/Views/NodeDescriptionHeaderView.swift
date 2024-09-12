import MEGADesignToken
import SwiftUI

struct NodeDescriptionHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String

    var body: some View {
        VStack {
            Text(title)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            TokenColors.Border.strong.swiftUI
                .frame(height: 0.5)
        }
        .padding(.top, 30)
        .background()
    }
}
