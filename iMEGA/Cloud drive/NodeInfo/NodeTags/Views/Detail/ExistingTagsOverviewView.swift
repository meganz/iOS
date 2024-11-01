import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ExistingTagsOverviewView: View {
    let viewModel: ExistingTagsViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.AddTags.existingTagsTitle)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .frame(maxWidth: .infinity, alignment: .leading)

            ExistingTagsView(viewModel: viewModel)
                .padding(.top, TokenSpacing._5)
        }
        .padding(
            EdgeInsets(top: TokenSpacing._5, leading: TokenSpacing._5, bottom: 0, trailing: TokenSpacing._5)
        )
    }
}
