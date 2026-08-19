import MEGAAssets
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

public struct PromoLandingDialogContentView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let compactContentLeadingPadding: CGFloat = 250

    @StateObject private var viewModel: PromoLandingDialogContentViewModel

    public init(dependency: PromoLandingDialogContentView.Dependency) {
        _viewModel = StateObject(wrappedValue: PromoLandingDialogContentViewModel(dependency: dependency))
    }

    private var isRegularHeight: Bool { verticalSizeClass != .compact }

    private var compactTopInset: CGFloat {
        isRegularHeight ? 0 : TokenSpacing._11
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            layoutView
                .background(TokenColors.Background.page.swiftUI)
                // Only the top and sides, so the banner still bleeds to the screen edge while the
                // bottom inset below keeps the content scrolling above the footer.
                .ignoresSafeArea(edges: [.top, .horizontal])

            PromoLandingDialogCloseButton(dismissAction: { viewModel.closeButtonTapped() })
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PromoLandingDialogFooterView(
                title: viewModel.card.buttonTitle,
                productIdentifier: viewModel.card.productIdentifier,
                planPurchaser: viewModel.planPurchaser,
                purchaseTracker: viewModel.purchaseTracker,
                onPurchased: { viewModel.purchaseCompleted() },
                viewAllPlans: viewModel.viewAllPlans
            )
        }
        .onAppear { viewModel.onAppear() }
    }

    // MARK: - Layout

    private var layoutView: some View {
        scrollContent
            .padding(.leading, isRegularHeight ? 0 : compactContentLeadingPadding)
            .background(alignment: .topLeading) {
                compactHeaderBackground.opacity(isRegularHeight ? 0 : 1)
            }
    }

    private var compactHeaderBackground: some View {
        MEGAAssets.Image.promoBanner
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: compactContentLeadingPadding)
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(TokenColors.Background.page.swiftUI)
            .ignoresSafeArea()
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if isRegularHeight {
                    SubscriptionPromoBannerView()
                }

                VStack(alignment: .leading, spacing: 0) {
                    SubscriptionPromoHeaderView(viewModel: viewModel.header)
                        .blendIntoHeader(offset: TokenSpacing._16, isCompact: !isRegularHeight)
                    SubscriptionPromoPlanCardView(card: viewModel.card)
                        .padding(.vertical, TokenSpacing._4)
                }
                .padding(.horizontal, TokenSpacing._5)
            }
            .padding(.top, compactTopInset)
            .padding(.bottom, TokenSpacing._2)
            .maxWidthForWideScreen()
        }
    }
}

private extension PromoLandingDialogContentViewModel {
    var header: SubscriptionPromoHeaderViewModel {
        SubscriptionPromoHeaderViewModel(plan: plan)
    }

    var card: SubscriptionRevampPromoPlanCardModel {
        SubscriptionPromoPlanCardPresenter(
            plan: plan,
            displayName: { $0.toAccountTypeDisplayName() }
        ).cardModel
    }
}
