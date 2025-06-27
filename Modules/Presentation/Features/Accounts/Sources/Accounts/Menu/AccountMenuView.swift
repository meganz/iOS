import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

public struct AccountMenuView: View {
    @StateObject var viewModel: AccountMenuViewModel

    public init(viewModel: @autoclosure @escaping () -> AccountMenuViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    public var body: some View {
        ZStack(alignment: .top) {
            contentView
            AccountMenuHeaderView(hideHeaderBackground: viewModel.isAtTop) {

            }
        }
        .toolbar(.hidden)
        .task {
            await viewModel.refreshAccountData()
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(height: 52)
                    .onScrollNearTop(
                        coordinateSpaceName: AccountMenuViewModel.Constants.coordinateSpaceName,
                        topInset: 0,
                        topOffsetThreshold: AccountMenuViewModel.Constants.topOffsetThreshold
                    ) { newValue in
                        guard viewModel.isAtTop != newValue else { return }
                        withAnimation(.easeInOut(duration: 0.4)) {
                            viewModel.isAtTop = newValue
                        }
                    }

                ForEach([AccountMenuSectionType.account, .tools], id: \.self) { section in
                    if let items = viewModel.sections[section] {
                        if let sectionName = section.description {
                            Text(sectionName)
                                .font(.caption)
                                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                                .padding([.horizontal, .top], section == .account ? TokenSpacing._5 : TokenSpacing._4)
                        }

                        ForEach(items) { option in
                            MenuRowView(option: option)
                        }

                        if section == .account {
                            Spacer().frame(height: TokenSpacing._5)
                        }
                    }
                }

                if let privacyItems = viewModel.sections[.privacySuite],
                    let title = AccountMenuSectionType.privacySuite.description {
                    CollapsibleSectionView(
                        title: title,
                        isExpanded: $viewModel.isPrivacySuiteExpanded,
                        options: privacyItems
                    )
                }

                Button {

                } label: {
                    Text(Strings.Localizable.AccountMenu.logout)
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(TokenColors.Text.accent.swiftUI)
                        .background(TokenColors.Button.secondary.swiftUI)
                        .cornerRadius(TokenRadius.medium)
                        .padding(.horizontal)
                        .padding(.vertical, TokenSpacing._6)
                }
            }
        }
        .coordinateSpace(name: AccountMenuViewModel.Constants.coordinateSpaceName)

    }
}

private struct AccountMenuHeaderView: View {
    let hideHeaderBackground: Bool
    let buttonTapped: () -> Void

    var body: some View {
        headerView
            .background {
                if !hideHeaderBackground {
                    backgroundBlurView
                }
            }
    }

    private var headerView: some View {
        HStack {
            Spacer()
            Button {
                buttonTapped()
            } label: {
                MEGAAssets.Image.notificationsInMenu
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(TokenColors.Icon.primary.swiftUI)
                    .padding(.vertical, TokenSpacing._2)
            }
        }
        .frame(height: 52)
        .padding(.horizontal, TokenSpacing._5)
    }

    private var backgroundBlurView: some View {
        VStack(spacing: 0) {
            Color
                .clear
                .background(Material.regular)
            Divider()
        }
    }
}

private struct MenuRowView: View {
    let option: AccountMenuOption

    var body: some View {
        MEGAList(title: option.title, subtitle: option.subtitle)
            .replaceLeadingView {
                leadingView
                    .foregroundStyle(option.iconConfiguration.backgroundColor)
                    .frame(width: 32, height: 32)
            }
            .replaceTrailingView {
                trailingView
            }
    }

    @ViewBuilder
    private var leadingView: some View {
        switch option.iconConfiguration.style {
        case .normal:
            option.iconConfiguration.icon
        case .rounded:
            option.iconConfiguration.icon
                .resizable()
                .clipShape(.circle)
                .aspectRatio(contentMode: .fill)
        }
    }

    @ViewBuilder
    private var trailingView: some View {
        switch option.rowType {
        case .withButton(let title, let action):
            upgradeButton(title: title, action: action)
        case .disclosure:
            Image(systemName: "chevron.right")
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                .font(.body)
        case .externalLink:
            MEGAAssets.Image.externalLink
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
        }
    }

    private func upgradeButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.subheadline)
            .padding(.horizontal, TokenSpacing._4)
            .padding(.vertical, TokenSpacing._3)
            .background(TokenColors.Text.primary.swiftUI)
            .foregroundStyle(TokenColors.Text.inverseAccent.swiftUI)
            .cornerRadius(TokenRadius.medium)
    }
}

private struct CollapsibleSectionView: View {
    let title: String
    @Binding var isExpanded: Bool
    let options: [AccountMenuOption]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                        .font(.caption2)
                }
                .padding(.horizontal)
                .padding(.top, TokenSpacing._4)
            }

            if isExpanded {
                ForEach(options) { option in
                    MenuRowView(option: option)
                }
            }
        }
    }
}
