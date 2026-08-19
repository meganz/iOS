import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct QuotaDialogView<
    Header: View,
    CurrentPlanCard: View,
    RecommendedPlanCard: View,
    Footer: View
>: View {
    private let trackingUseCase: any QuotaDialogTrackingUseCaseProtocol
    private let header: Header
    private let currentPlanCard: CurrentPlanCard?
    private let recommendedPlanCard: RecommendedPlanCard?
    private let footer: Footer

    init(
        trackingUseCase: some QuotaDialogTrackingUseCaseProtocol,
        @ViewBuilder header: () -> Header,
        @ViewBuilder currentPlanCard: () -> CurrentPlanCard?,
        @ViewBuilder recommendedPlanCard: () -> RecommendedPlanCard,
        @ViewBuilder footer: () -> Footer
    ) {
        self.trackingUseCase = trackingUseCase
        self.header = header()
        self.currentPlanCard = currentPlanCard()
        self.recommendedPlanCard = recommendedPlanCard()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: TokenSpacing._7) {
                    header
                    if let currentPlanCard {
                        currentPlanCard
                    }
                    if let recommendedPlanCard {
                        recommendedPlanCard
                    }
                }
                .padding(.horizontal, TokenSpacing._5)
                .padding(.bottom, TokenSpacing._5)
                .maxWidthForWideScreen()
                .frame(maxWidth: .infinity)
            }
            footer
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(TokenColors.Border.subtle.swiftUI)
                        .frame(height: 1)
                }
        }
        .background(TokenColors.Background.page.swiftUI)
        .onAppear { trackingUseCase.trackScreenView() }
    }
}

extension QuotaDialogView where RecommendedPlanCard == EmptyView {
    init(
        trackingUseCase: some QuotaDialogTrackingUseCaseProtocol,
        @ViewBuilder header: () -> Header,
        @ViewBuilder currentPlanCard: () -> CurrentPlanCard,
        @ViewBuilder footer: () -> Footer
    ) {
        self.trackingUseCase = trackingUseCase
        self.header = header()
        self.currentPlanCard = currentPlanCard()
        self.recommendedPlanCard = nil
        self.footer = footer()
    }
}

extension QuotaDialogView where CurrentPlanCard == EmptyView {
    init(
        trackingUseCase: some QuotaDialogTrackingUseCaseProtocol,
        @ViewBuilder header: () -> Header,
        @ViewBuilder recommendedPlanCard: () -> RecommendedPlanCard,
        @ViewBuilder footer: () -> Footer
    ) {
        self.trackingUseCase = trackingUseCase
        self.header = header()
        self.currentPlanCard = nil
        self.recommendedPlanCard = recommendedPlanCard()
        self.footer = footer()
    }
}
