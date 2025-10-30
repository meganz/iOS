import MEGADesignToken
import SwiftUI

struct SearchResultsHeaderViewModeView: View {
    @StateObject var viewModel: SearchResultsHeaderViewModeViewModel

    var body: some View {
        Menu {
            Picker("View Mode Selection", selection: $viewModel.selectedViewMode) {
                ForEach(viewModel.availableViewModes, id: \.self) { viewMode in
                    Label {
                        Text(viewMode.title)
                            .font(.body)
                            .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    } icon: {
                        viewMode.icon
                    }
                }
            }
        } label: {
            Label {
                Text(viewModel.title)
            } icon: {
                viewModel
                    .image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                    .padding(.horizontal, TokenSpacing._7)
                    .frame(height: 36)
            }
            .labelStyle(.iconOnly)
        }
    }
}
