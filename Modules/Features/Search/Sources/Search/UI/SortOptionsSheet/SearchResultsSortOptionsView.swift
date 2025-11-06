import MEGADesignToken
import SwiftUI

struct SearchResultsSortOptionsView: View {
    let viewModel: SearchResultsSortOptionsViewModel
    let height: CGFloat

    init(viewModel: SearchResultsSortOptionsViewModel, height: CGFloat = 58) {
        self.viewModel = viewModel
        self.height = height
    }

    var body: some View {
        VStack {
            titleView
            ScrollView {
                LazyVStack(spacing: 0) {
                    SortOptionsView(
                        sortOptions: viewModel.sortOptions,
                        height: height,
                        tapHandler: viewModel.tapHandler
                    )
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, TokenSpacing._5)
        .presentationDetents([.medium, .large])
    }

    private var titleView: some View {
        Text(viewModel.title)
            .font(.body)
            .bold()
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .frame(height: height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, TokenSpacing._6)
    }
}

private struct SortOptionsView: View {
    let sortOptions: [SearchResultsSortOption]
    let height: CGFloat
    let tapHandler: SearchResultsSortOptionsViewModel.TapHandler?

    var body: some View {
        ForEach(sortOptions) { option in
            SortOptionView(name: option.title, icon: option.toggledDirectionIcon, height: height) {
                tapHandler?(option)
            }
        }
    }
}

private struct SortOptionView: View {
    let name: String
    let icon: Image?
    let height: CGFloat
    let handler: () -> Void

    var body: some View {
        Button {
            handler()
        } label: {
            HStack {
                Text(name)
                    .font(.body)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)

                Spacer()
                if let icon = icon {
                    icon
                        .resizable()
                        .frame(width: 16, height: 16)
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                }
            }
        }
        .frame(height: height)
    }
}
