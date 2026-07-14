import MEGAAssets
import MEGADesignToken
import MEGADomain
import SwiftUI

/// The promo redesigned subscription page.
///
/// A promo banner with a fade-out gradient, the promo hero card, then the
/// shared plan/feature/benefit sections. Driven by mock data.
struct SubscriptionRevampPromoView: View {
    private let promoHeader: SubscriptionPromoHeaderModel
    @State private var selectedCycle: SubscriptionCycleEntity = .yearly

    init(promoHeader: SubscriptionPromoHeaderModel) {
        self.promoHeader = promoHeader
    }

    var body: some View {
        SubscriptionRevampBaseView(
            compactHeaderImage: MEGAAssets.Image.promoBanner
        ) {
            promoBanner
        } content: {
            promoHero
            cyclePicker
            SubscriptionPlanCardsView()
            SubscriptionProFeaturesView(features: SubscriptionRevampMockData.features)
            SubscriptionBenefitsListView(benefits: SubscriptionRevampMockData.benefits)
            SubscriptionLegalFooterView()
        }
    }

    private var promoBanner: some View {
        MEGAAssets.Image.promoBanner
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 221)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.614),
                        .init(color: TokenColors.Background.page.swiftUI, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }

    private var promoHero: some View {
        SubscriptionPromoHeaderView(model: promoHeader)
            .padding(TokenSpacing._5)
            .background(
                TokenColors.Background.surface1.swiftUI,
                in: RoundedRectangle(cornerRadius: TokenRadius.medium)
            )
    }

    private var cyclePicker: some View {
        SubscriptionCyclePickerView(
            options: SubscriptionRevampMockData.cycleOptions,
            selection: $selectedCycle,
            title: SubscriptionRevampMockData.cycleTitle,
            savingText: SubscriptionRevampMockData.savingText
        )
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SubscriptionRevampPromoView(promoHeader: SubscriptionRevampMockData.promoHeader)
}
