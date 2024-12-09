import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct NodeTagsCellView: View {

    @StateObject var viewModel: NodeTagsCellViewModel

    var body: some View {
        VStack {
            header
            if viewModel.tags.isNotEmpty {
                NodeTagsView(viewModel: viewModel.nodeTagsViewModel)
                    .padding(.top, TokenSpacing._3)
            }
        }
        .padding(
            EdgeInsets(
                top: TokenSpacing._4,
                leading: TokenSpacing._5,
                bottom: TokenSpacing._4,
                trailing: TokenSpacing._5
            )
        )
    }

    private var header: some View {
        HStack {
            Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.header)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                .opacity(viewModel.isExpiredBusinessOrProFlexiAccount ? 0 : 1)
        }
    }
}
