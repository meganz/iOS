import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct NodeTagsCellView: View {

    @StateObject var viewModel: NodeTagsCellViewModel

    var body: some View {
        VStack {
            HStack {
                Text(Strings.Localizable.CloudDrive.NodeInfo.NodeTags.header)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                proBagdeView
                Spacer()
                disclosureView
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
        .task {
            await viewModel.startMonitoringAccountDetails()
        }
    }
    
    @ViewBuilder
    private var proBagdeView: some View {
        if viewModel.isLoading {
            ProgressView()
                .padding(.leading, TokenSpacing._2)
        } else if viewModel.showsProTag {
            AvailableForProOnlyView(
                proOnlyText: Strings.Localizable.CloudDrive.NodeInfo.NodeTags.Feature.availableForProOnlyText,
                foregroundColor: TokenColors.Button.brand.swiftUI,
                borderColor: TokenColors.Button.brand.swiftUI,
                cornerRadius: TokenRadius.extraSmall
            )
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var disclosureView: some View {
        if !viewModel.isLoading && viewModel.hasValidSubscription {
            Image(systemName: "chevron.right")
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
        } else {
            EmptyView()
        }
    }
}
