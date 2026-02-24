import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGASwiftUI
import SwiftUI

struct AccountDetailsWidgetView: View {
    struct Dependency {
        let fullNameHandler: @Sendable (CurrentUserSource) -> String
        let userImageUseCase: any UserImageUseCaseProtocol
        let avatarFetcher: @Sendable () async -> Image?
    }

    @StateObject private var viewModel: AccountDetailsWidgetViewModel
    private let accessoryButtonAction: @MainActor () -> Void

    private enum Constants {
        static let avatarSize = 32.0
        static let progressBarHeight = 2.0
    }

    init(dependency: Dependency, accessoryButtonAction: @escaping @MainActor () -> Void) {
        _viewModel = StateObject(
            wrappedValue: AccountDetailsWidgetViewModel(
                dependency: .init(
                    fullNameHandler: dependency.fullNameHandler,
                    avatarFetcher: dependency.avatarFetcher
                )
            )
        )

        self.accessoryButtonAction = accessoryButtonAction
    }

    var body: some View {
        HStack(alignment: .plan, spacing: TokenSpacing._4) {
            avatar
            accountDetails
            trailingAccessory
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, TokenSpacing._4)
        .background(TokenColors.Background.surface1.swiftUI)
        .cornerRadius(TokenRadius.medium)
        .padding(.vertical, TokenSpacing._4)
        .padding(.horizontal, TokenSpacing._5)
        .task {
            await viewModel.onTask()
        }
    }

    private var avatar: some View {
        viewModel.profilePicture
            .resizable()
            .scaledToFill()
            .frame(width: Constants.avatarSize, height: Constants.avatarSize)
            .clipShape(Circle())
            .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
            .padding(.leading, TokenSpacing._4)
            .alignmentGuide(.plan) { $0[VerticalAlignment.center] }
    }

    private var accountDetails: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._2) {
            userName
            plan
            storageUsage
            if viewModel.storageUsedFraction > 0 {
                progressBar
            }
        }
    }

    private var userName: some View {
        Text(viewModel.title)
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
    }

    private var plan: some View {
        Text(viewModel.plan)
            .font(.subheadline)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .alignmentGuide(.plan) { $0[VerticalAlignment.center] }
    }

    private var storageUsage: some View {
        Text(viewModel.storageUsage)
            .font(.caption)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(TokenColors.Background.surface3.swiftUI)
                Rectangle()
                    .fill(viewModel.storageUsedFractionColor)
                    .frame(width: geometry.size.width * viewModel.storageUsedFraction)
            }
        }
        .frame(height: Constants.progressBarHeight)
        .padding(.trailing, viewModel.shouldShowUpgrade ? 0 : TokenSpacing._5)
    }

    @ViewBuilder
    private var trailingAccessory: some View {
        if viewModel.shouldShowUpgrade {
            Button {
                accessoryButtonAction()
            } label: {
                MEGAAssets.Image.chevronRight
                    .renderingMode(.template)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    .frame(width: 24, height: 24)
            }
            .alignmentGuide(.plan) { $0[VerticalAlignment.center] }
            .padding(.trailing, TokenSpacing._5)
        }

    }
}

// Custom alignment to vertically center the avatar and the plan
private extension VerticalAlignment {
    struct PlanAlignment: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center]
        }
    }
    static let plan = VerticalAlignment(PlanAlignment.self)
}
