import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct RecentsWidgetView: View {
    struct Dependency {
        let userNameProvider: any UserNameProviderProtocol
    }
    
    private let dependency: Dependency
    @StateObject private var viewModel = RecentsWidgetViewModel()

    init(dependency: Dependency) {
        self.dependency = dependency
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .padding(.vertical, TokenSpacing._4)
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
        .padding(.horizontal, TokenSpacing._5)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case let .nonEmpty(bucketGroups):
            nonEmptyContent(bucketGroups: bucketGroups)
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

    private func nonEmptyContent(bucketGroups: [DailyRecentActionBucketGroup]) -> some View {
        RecentWidgetBucketListView(
            dependency: RecentWidgetBucketListView.Dependency(
                bucketGroups: bucketGroups,
                userNameProvider: dependency.userNameProvider
            )
        )
    }
}
