import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct NodeTagsCellView: View {

    private let viewModel: NodeTagsCellViewModel

    init(viewModel: NodeTagsCellViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            HStack {
                Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.header)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)

                if viewModel.shouldShowProTag {
                    AvailableForProOnlyView(
                        proOnlyText: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.Feature.availableForProOnlyText,
                        foregroundColor: TokenColors.Button.brand.swiftUI,
                        borderColor: TokenColors.Button.brand.swiftUI,
                        cornerRadius: TokenRadius.extraSmall
                    )
                }

                Spacer()

                if viewModel.hasValidSubscription {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                }
            }

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
}
