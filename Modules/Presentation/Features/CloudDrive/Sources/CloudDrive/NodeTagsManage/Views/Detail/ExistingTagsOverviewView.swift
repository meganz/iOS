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

            if viewModel.hasReachedMaxLimit {
                limitReachedView
            }

            ExistingTagsView(viewModel: viewModel)
                .padding(.top, viewModel.hasReachedMaxLimit ? TokenSpacing._3 : TokenSpacing._5)
        }
        .padding(
            EdgeInsets(top: TokenSpacing._5, leading: TokenSpacing._5, bottom: 0, trailing: TokenSpacing._5)
        )
    }

    private var limitReachedView: some View {
        Text(viewModel.maxLimitReachedAlertMessage)
            .font(.caption2.bold())
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .padding(.vertical, TokenSpacing._4)
            .padding(.horizontal, TokenSpacing._5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TokenColors.Notifications.notificationWarning.swiftUI)
    }
}
