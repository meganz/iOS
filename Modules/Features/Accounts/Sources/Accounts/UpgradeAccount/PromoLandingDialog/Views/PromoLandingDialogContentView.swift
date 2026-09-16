import MEGAAssets
import MEGADesignToken
import MEGAUIComponent
import SwiftUI

public struct PromoLandingDialogContentView: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var isPadLandscape = false

    private let compactContentLeadingPadding: CGFloat = 250
    private let padLandscapeContentLeadingPadding: CGFloat = 391

    @StateObject private var viewModel: PromoLandingDialogContentViewModel

    public init(dependency: PromoLandingDialogContentView.Dependency) {
        _viewModel = StateObject(wrappedValue: PromoLandingDialogContentViewModel(dependency: dependency))
    }

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var isSideBySide: Bool { verticalSizeClass == .compact || isPadLandscape }

    private var contentLeadingPadding: CGFloat {
        isPadLandscape ? padLandscapeContentLeadingPadding : compactContentLeadingPadding
    }

    private var sideBySideTopInset: CGFloat {
        isSideBySide ? TokenSpacing._11 : 0
    }

    private var footerLeadingInset: CGFloat {
        isSideBySide ? contentLeadingPadding : 0
    }

    private var footerIgnoredEdges: Edge.Set {
        isSideBySide ? .horizontal : []
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
                isOfferExpired: viewModel.isOfferExpired,
                isSideBySide: isSideBySide,
                planPurchaser: viewModel.planPurchaser,
                purchaseTracker: viewModel.purchaseTracker,
                onPurchased: { viewModel.purchaseCompleted() },
                viewAllPlans: viewModel.viewAllPlans
            )
            .padding(.leading, footerLeadingInset)
            .ignoresSafeArea(edges: footerIgnoredEdges)
        }
        .background { orientationReader }
        .onAppear { viewModel.onAppear() }
        .task { await viewModel.monitorOfferExpiry() }
    }

    // MARK: - Layout

    private var layoutView: some View {
        scrollContent
            .padding(.leading, isSideBySide ? contentLeadingPadding : 0)
            .frame(maxWidth: .infinity)
            .background(alignment: .topLeading) {
                leadingHeaderBackground.opacity(isSideBySide ? 1 : 0)
            }
    }

    private var orientationReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onChange(of: proxy.size, initial: true) { _, size in
                    isPadLandscape = isPad && size.width > size.height
                }
        }
        .ignoresSafeArea()
    }

    private var leadingHeaderBackground: some View {
        MEGAAssets.Image.promoBanner
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: contentLeadingPadding)
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(TokenColors.Background.page.swiftUI)
            .ignoresSafeArea()
    }

    // MARK: - Scroll content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                if !isSideBySide {
                    SubscriptionPromoBannerView()
                }

                VStack(alignment: .leading, spacing: 0) {
                    SubscriptionPromoHeaderView(viewModel: viewModel.header)
                        .blendIntoHeader(offset: TokenSpacing._16, isSideBySide: isSideBySide)
                    SubscriptionPromoPlanCardView(card: viewModel.card)
                        .padding(.vertical, TokenSpacing._4)
                }
                .padding(.horizontal, TokenSpacing._5)
                .if(!isSideBySide) { $0.maxWidthForWideScreen() }
            }
            .padding(.top, sideBySideTopInset)
            .padding(.bottom, TokenSpacing._2)
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
