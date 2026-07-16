import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

/// The standard (non-promo) redesigned subscription page.
///
/// A plain landscape header image, the "Upgrade to MEGA Pro" title, then the
/// shared plan/feature/benefit sections. Driven by mock data.
public struct SubscriptionRevampStandardView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    private let viewModel: RevampUpgradePlansViewModel

    init(viewModel: RevampUpgradePlansViewModel) {
        self.viewModel = viewModel
    }

    public init() { // To be removed, temporarily used for testing purpose
        self.init(viewModel: .standard)
    }

    public var body: some View {
        SubscriptionRevampBaseView(
            compactHeaderImage: MEGAAssets.Image.subscriptionImageHeaderLandscape
        ) {
            headerImage
        } content: {
            titleHeader
            SubscriptionRevampContentSectionsView(viewModel: viewModel)
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

#Preview {
    SubscriptionRevampStandardView()
}
