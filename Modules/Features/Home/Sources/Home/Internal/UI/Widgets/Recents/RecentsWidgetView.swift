import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct RecentsWidgetView: View {
    @StateObject private var viewModel = RecentsWidgetViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .padding(.vertical, TokenSpacing._4)
        .padding(.horizontal, TokenSpacing._5)
        .task {
            await viewModel.onTask()
        }
    }

    private var header: some View {
        HStack(spacing: TokenSpacing._3) {
            Text(Strings.Localizable.recents)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)

            Spacer()

            Button(action: {
                viewModel.didTapMoreButton()
            }, label: {
                Label {
                    Text(Strings.Localizable.more)
                } icon: {
                    MEGAAssets.Image.moreHorizontal
                        .renderingMode(.template)
                        .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                        .frame(width: 24, height: 24)
                }
                .labelStyle(.iconOnly)
            })
        }
        .padding(.bottom, TokenSpacing._3)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .nonEmpty:
            nonEmptyContent
        case .empty, .hidden:
            emptyOrHiddenContent
        }
    }

    private var emptyOrHiddenContent: some View {
        Text(RecentsWidgetViewModel.placeholderDescription)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nonEmptyContent: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            Text(RecentsWidgetViewModel.placeholderDescription)
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)

            RoundedRectangle(cornerRadius: TokenRadius.medium)
                .stroke(TokenColors.Border.strong.swiftUI, style: StrokeStyle(lineWidth: 1, dash: [4]))
                .frame(height: 72)
                .overlay(
                    Text("Non-empty content placeholder")
                        .font(.footnote)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                )

            Button {
                viewModel.didTapLowerButton()
            } label: {
                Text(RecentsWidgetViewModel.placeholderButtonTitle)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .underline()
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .frame(height: 32, alignment: .center)
            }
            .padding(.bottom, TokenSpacing._2)
        }
    }
}
