import MEGADesignToken
import SwiftUI

public struct SearchResultsHeaderSortView: View {
    @StateObject private var viewModel: SearchResultsHeaderSortViewViewModel

    public init(viewModel: @autoclosure @escaping () -> SearchResultsHeaderSortViewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        Button {
            viewModel.showSortSheet = true
        } label: {
            HStack(spacing: TokenSpacing._3) {
                Text(viewModel.selectedOption.title)
                    .font(.subheadline)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)

                if let icon = viewModel.selectedOption.currentDirectionIcon {
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
        .sheet(isPresented: $viewModel.showSortSheet) {
            SearchResultsSortOptionsView(viewModel: viewModel.displaySortOptionsViewModel)
        }
    }
}
