import MEGAAssets
import MEGADesignToken
import MEGADomain
import SwiftUI

/// The standard (non-promo) redesigned subscription page.
///
/// A plain landscape header image, the "Upgrade to MEGA Pro" title, then the
/// shared plan/feature/benefit sections. Driven by mock data.
public struct SubscriptionRevampStandardView: View {
    @State private var selectedCycle: SubscriptionCycleEntity = .yearly
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    public init() {}

    public var body: some View {
        SubscriptionRevampBaseView(
            compactHeaderImage: MEGAAssets.Image.subscriptionImageHeaderLandscape
        ) {
            headerImage
        } content: {
            titleHeader
            SubscriptionProFeaturesView(features: SubscriptionRevampMockData.features)
                .padding(.top, TokenSpacing._3)
            SubscriptionCurrentPlanView(viewModel: SubscriptionRevampMockData.currentPlan)
                .padding(.top, TokenSpacing._3)
            cyclePicker
                .padding(.top, TokenSpacing._3)
            SubscriptionPlanCardsView()
                .padding(.top, TokenSpacing._3)
            SubscriptionBenefitsListView(benefits: SubscriptionRevampMockData.benefits)
                .padding(.top, TokenSpacing._3)
            SubscriptionLegalFooterView()
                .padding(.bottom, TokenSpacing._13)
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
            .overlay(alignment: .bottom) {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: TokenColors.Background.page.swiftUI, location: 0.6),
                        .init(color: TokenColors.Background.page.swiftUI, location: 1.0)
                    ],
                    startPoint: UnitPoint(x: 0.5, y: 0),
                    endPoint: UnitPoint(x: 0.5, y: 1)
                )
                .frame(height: 120)
            }
    }

    private var titleHeader: some View {
        Text("Upgrade to MEGA Pro") // To be localized later
            .font(.title.bold())
            .foregroundStyle(TokenColors.Text.primary.swiftUI)
            .padding(.top, verticalSizeClass != .compact ? -TokenSpacing._11 : 0) // In non-compact mode, the title needs to blend into the header to achieve the designated UI
    }

    private var cyclePicker: some View {
        SubscriptionCyclePickerView(
            options: SubscriptionRevampMockData.cycleOptions,
            selection: $selectedCycle,
            title: SubscriptionRevampMockData.cycleTitle,
            savingText: SubscriptionRevampMockData.savingText
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, TokenSpacing._7)
        .padding(.bottom, TokenSpacing._4)
    }
}

#Preview {
    SubscriptionRevampStandardView()
}
