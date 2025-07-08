import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

struct SubscriptionPurchasePageContentView: View {
    private let coordinateSpaceName = "Scroll"
    @State private var topInset: CGFloat = 0
    let topOffsetThreshold: CGFloat
    @Binding var isAtTop: Bool
    @ObservedObject var viewModel: UpgradeAccountPlanViewModel
    private let getStartedButtonTapped: () -> Void
    private let isRegularHeight: Bool

    init(
        topOffsetThreshold: CGFloat,
        isAtTop: Binding<Bool>,
        viewModel: UpgradeAccountPlanViewModel,
        isRegularHeight: Bool,
        getStartedButtonTapped: @escaping () -> Void
    ) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._isAtTop = isAtTop
        self.topOffsetThreshold = topOffsetThreshold
        self.isRegularHeight = isRegularHeight
        self.getStartedButtonTapped = getStartedButtonTapped
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: isRegularHeight ? 0 : 76)
                    .onScrollNearTop(
                        coordinateSpaceName: coordinateSpaceName,
                        topInset: topInset,
                        topOffsetThreshold: topOffsetThreshold
                    ) { newValue in
                        guard isAtTop != newValue else { return }
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isAtTop = newValue
                        }
                    }

                if isRegularHeight {
                    headerImage
                }

                VStack(alignment: .leading, spacing: 0) {
                    titleView
                    subtitleView
                    SubscriptionPurchaseFeaturesView()
                    SubscriptionPurchasePlansView(viewModel: viewModel)
                    SubscriptionPurchaseBenefitsView()
                    if let freePlanViewModel = viewModel.freePlanViewModel {
                        SubscriptionPurchaseFreePlanView(
                            viewModel: freePlanViewModel,
                            freeButtonTapped: getStartedButtonTapped)
                    }
                    
                    VStack(alignment: .leading, spacing: TokenSpacing._7) {
                        subscriptionDetails
                        restorePurchase
                        termsAndPolicies
                    }
                }
                .padding(.horizontal, isRegularHeight ? TokenSpacing._5 :  TokenSpacing._11)
                .maxWidthForWideScreen()
            }
        }
        .background(TokenColors.Background.page.swiftUI)
        .ignoresSafeArea(.all, edges: .top)
        .coordinateSpace(name: coordinateSpaceName)
        .onTopInsetChange { topInset = $0 }
    }

    private var headerImage: some View {
        MEGAAssets.Image.subscriptionImageHeader
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 164)
            .clipped()
    }

    private var titleView: some View {
        Text(Strings.Localizable.Onboarding.UpgradeAccount.Header.title)
            .font(.title2.bold())
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .padding(.top, TokenSpacing._5)
            .padding(.bottom, TokenSpacing._2)
    }

    private var subtitleView: some View {
        Text(Strings.Localizable.SubscriptionPurchase.Feature.title)
            .font(.headline)
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .padding(.top, TokenSpacing._3)
            .padding(.bottom, TokenSpacing._5)
    }

    private var subscriptionDetails: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            Text(Strings.Localizable.UpgradeAccountPlan.Header.Title.subscriptionDetails)
                .font(.subheadline.bold())
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            TextWithLinkView(details: viewModel.autoRenewDescription)
                .font(.caption)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .tint(TokenColors.Link.primary.swiftUI)
        }
        .padding(.top, TokenSpacing._5)
    }

    private var restorePurchase: some View {
        Button {
            viewModel.didTap(.restorePlan)
        } label: {
            Text(Strings.Localizable.UpgradeAccountPlan.Button.Restore.title)
                .font(.footnote.bold())
                .foregroundStyle(TokenColors.Link.primary.swiftUI)
        }
    }

    private var termsAndPolicies: some View {
        Button {
            viewModel.didTap(.termsAndPolicies)
        } label: {
            Text(Strings.Localizable.Settings.Section.termsAndPolicies)
                .font(.footnote.bold())
                .foregroundStyle(TokenColors.Link.primary.swiftUI)
        }
        .padding(.bottom, TokenSpacing._9)
    }
}
