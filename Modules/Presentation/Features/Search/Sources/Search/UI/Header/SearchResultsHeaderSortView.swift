import MEGADesignToken
import SwiftUI

struct SearchResultsHeaderSortView: View {
    let viewModel: SearchResultsHeaderSortViewViewModel

    var body: some View {
        Button {
            viewModel.handler()
        } label: {
            HStack(spacing: TokenSpacing._3) {
                Text(viewModel.title)
                    .font(.subheadline)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)

                if let icon = viewModel.icon {
                    icon
                        .resizable()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 36)
        .padding(.horizontal, TokenSpacing._5)
    }
}
