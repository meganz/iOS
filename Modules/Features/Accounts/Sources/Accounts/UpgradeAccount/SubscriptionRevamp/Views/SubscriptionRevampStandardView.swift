import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import SwiftUI

/// The standard (non-promo) redesigned subscription page.
///
/// A plain landscape header image, the "Upgrade to MEGA Pro" title, then the
/// shared plan/feature/benefit sections. Driven by mock data.
public struct SubscriptionStandardView: View {
    private let dependency: RevampUpgradePlansDependency
    private let viewModel: UpgradePlansViewModel
    private let purchaseViewModel: PlanPurchaseViewModel
    private let externalPurchaseViewModel: ExternalPurchaseViewModel?
    private let dismiss: (UpgradePlansDismissReason) -> Void

    init(
        dependency: RevampUpgradePlansDependency,
        viewModel: UpgradePlansViewModel,
        purchaseViewModel: PlanPurchaseViewModel,
        externalPurchaseViewModel: ExternalPurchaseViewModel?,
        dismiss: @escaping (UpgradePlansDismissReason) -> Void
    ) {
        self.viewModel = viewModel
        self.dependency = dependency
        self.purchaseViewModel = purchaseViewModel
        self.externalPurchaseViewModel = externalPurchaseViewModel
        self.dismiss = dismiss
    }

    public var body: some View {
        SubscriptionBaseView(
            leadingHeaderImage: MEGAAssets.Image.subscriptionImageHeaderLandscape,
            dependency: dependency,
            dismiss: dismiss
        ) {
            headerImage
        } content: { isSideBySide in
            titleHeader(isSideBySide: isSideBySide)
            SubscriptionContentSectionsView(
                dependency: dependency,
                viewModel: viewModel,
                purchaseViewModel: purchaseViewModel,
                externalPurchaseViewModel: externalPurchaseViewModel,
                dismiss: dismiss
            )
        }
        .planPurchaseAlert(purchaseViewModel)
        .externalPurchaseAlert(externalPurchaseViewModel)
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

    private func titleHeader(isSideBySide: Bool) -> some View {
        Text(Strings.Localizable.SubscriptionPurchase.title)
            .font(.title.bold())
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .blendIntoHeader(offset: TokenSpacing._11, isSideBySide: isSideBySide)
    }
}
