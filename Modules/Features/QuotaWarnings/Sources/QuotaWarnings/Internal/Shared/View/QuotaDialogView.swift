import MEGADesignToken
import MEGAUIComponent
import SwiftUI

struct QuotaDialogView<
    Header: View,
    CurrentPlanCard: View,
    RecommendedPlanCard: View,
    Footer: View
>: View {
    private let header: Header
    private let currentPlanCard: CurrentPlanCard
    private let recommendedPlanCard: RecommendedPlanCard?
    private let footer: Footer

    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder currentPlanCard: () -> CurrentPlanCard,
        @ViewBuilder recommendedPlanCard: () -> RecommendedPlanCard,
        @ViewBuilder footer: () -> Footer
    ) {
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
                    currentPlanCard
                    if let recommendedPlanCard {
                        recommendedPlanCard
                    }
                }
                .padding(.horizontal, TokenSpacing._5)
                .padding(.vertical, TokenSpacing._9)
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
    }
}

extension QuotaDialogView where RecommendedPlanCard == EmptyView {
    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder currentPlanCard: () -> CurrentPlanCard,
        @ViewBuilder footer: () -> Footer
    ) {
        self.header = header()
        self.currentPlanCard = currentPlanCard()
        self.recommendedPlanCard = nil
        self.footer = footer()
    }
}
