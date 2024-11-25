import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ExistingTagsOverviewView: View {
    @ObservedObject var viewModel: ExistingTagsViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.existingTagsTitle)
                .font(.footnote)
                .foregroundStyle(viewModel.isLoading ? .clear : TokenColors.Text.secondary.swiftUI)
                .background(viewModel.isLoading ? TokenColors.Background.surface2.swiftUI : .clear)
                .cornerRadius(TokenSpacing._5)
                .frame(maxWidth: .infinity, alignment: .leading)

            ExistingTagsView(viewModel: viewModel)
                .padding(.top, TokenSpacing._5)
        }
        .padding(
            EdgeInsets(top: TokenSpacing._5, leading: TokenSpacing._5, bottom: 0, trailing: TokenSpacing._5)
        )
    }
}
