import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

/// The standard (non-promo) redesigned subscription page.
///
/// A plain landscape header image, the "Upgrade to MEGA Pro" title, then the
/// shared plan/feature/benefit sections. Driven by mock data.
public struct SubscriptionStandardView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let dependency: RevampUpgradePlansDependency
    private let viewModel: UpgradePlansViewModel
    private let dismissAction: () -> Void

    init(
        dependency: RevampUpgradePlansDependency,
        viewModel: UpgradePlansViewModel,
        dismissAction: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.dependency = dependency
        self.dismissAction = dismissAction
    }

    public var body: some View {
        SubscriptionBaseView(
            compactHeaderImage: MEGAAssets.Image.subscriptionImageHeaderLandscape,
            closeButtonType: .init(viewType: dependency.viewType),
            dismissAction: dismissAction
        ) {
            headerImage
        } content: {
            titleHeader
            SubscriptionContentSectionsView(dependency: dependency, viewModel: viewModel)
        }
    }

    private var headerImage: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 280)
            .overlay {
                MEGAAssets.Image.subscriptionImageHeaderRevamp
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            .clipped()
            .subscriptionHeaderBottomFade()
    }

    private var titleHeader: some View {
        Text(Strings.Localizable.SubscriptionPurchase.title)
            .font(.title.bold())
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .blendIntoHeader(offset: TokenSpacing._11, isCompact: verticalSizeClass == .compact)
    }
}
