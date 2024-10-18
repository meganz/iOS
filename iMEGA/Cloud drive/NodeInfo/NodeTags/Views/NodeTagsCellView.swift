import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct NodeTagsCellView: View {

    let viewModel: NodeTagsCellViewModel

    var body: some View {
        HStack {
            Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.header)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            if !viewModel.shouldShowProTag {
                AvailableForProOnlyView(
                    proOnlyText: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.Feature.availableForProOnlyText,
                    foregroundColor: TokenColors.Button.brand.swiftUI,
                    borderColor: TokenColors.Button.brand.swiftUI,
                    cornerRadius: TokenRadius.extraSmall
                )
            }

            Spacer()

            if viewModel.shouldShowProTag {
                Image(systemName: "chevron.right")
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
            }
        }
        .padding(.horizontal, 16)
    }
}
