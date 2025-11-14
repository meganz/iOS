import Accounts
import MEGADesignToken
import MEGAL10n
import MEGAUIComponent
import SwiftUI

struct SubscriptionPurchasePlanCardView: View {
    let viewModel: AccountPlanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            HStack {
                Text(viewModel.plan.name)
                    .font(.headline)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                
                if let planBadge = viewModel.planBadge {
                    MEGABadge(
                        text: planBadge.text,
                        type: planBadge.type,
                        size: .small,
                        icon: nil
                    )
                    .cornerRadius(TokenRadius.small)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(TokenColors.Components.selectionControl.swiftUI, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if viewModel.isSelected {
                        Circle()
                            .fill(TokenColors.Components.selectionControl.swiftUI)
                            .frame(width: 12, height: 12)
                    }
                }
                .opacity(viewModel.isSelectionEnabled ? 1 : 0)
            }
            .padding(.bottom, TokenSpacing._3)

            HStack {
                VStack(alignment: .leading) {
                    Text(Strings.Localizable.SubscriptionPurchase.Plan.storage(viewModel.plan.storage))
                        .font(.subheadline.bold())

                    Text(Strings.Localizable.SubscriptionPurchase.Plan.transfer(viewModel.plan.transfer))
                        .font(.subheadline.bold())
                }

                Spacer()

                priceView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: TokenRadius.medium)
                .stroke(
                    viewModel.isSelected ? TokenColors.Border.strongSelected.swiftUI : TokenColors.Border.strong.swiftUI,
                    lineWidth: viewModel.isSelected ? 2 : 1
                )
        )
        .onTapGesture {
            viewModel.didTapPlan()
        }
    }

    @ViewBuilder
    private var priceView: some View {
        switch viewModel.plan.subscriptionCycle {
        case .none:
            EmptyView()
        case .monthly:
            monthlyPriceView
        case .yearly:
            if viewModel.isNewYearlyPlanStyleEnabled {
                // The new yearly price view takes yearly price as dominant text.
                newYearlyPriceView
            } else {
                yearlyPriceView
            }
        }
    }

    private var formattedMonthlyPriceForYearlyPlan: String {
        viewModel.plan.formattedMonthlyPriceForYearlyPlan ?? ""
    }

    private var formattedPriceForYearlyPlan: String {
        viewModel.plan.formattedPriceForYearlyPlan ?? ""
    }

    private var yearlyPriceView: some View {
        VStack(alignment: .trailing) {
            if let introductoryOfferInfo = viewModel.introductoryOfferInfo() {
                Text(formattedMonthlyPriceForYearlyPlan)
                    .font(.caption)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .strikethrough()
                Text(attributedPricePerMonth(for: introductoryOfferInfo.formattedIntroPricePerMonth))
                IntroductoryOfferYearlyPriceBottomView(introductoryOfferInfo: introductoryOfferInfo)
            } else {
                Text(attributedPricePerMonth(for: formattedMonthlyPriceForYearlyPlan))
                Text(Strings.Localizable.SubscriptionPurchase.Plan.billedYearly(viewModel.plan.formattedPrice))
                    .font(.footnote)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            }
        }
    }

    private var newYearlyPriceView: some View {
        VStack(alignment: .trailing, spacing: TokenSpacing._1) {
            if let introductoryOfferInfo = viewModel.introductoryOfferInfo() {
                Text(formattedMonthlyPriceForYearlyPlan)
                    .font(.caption)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .strikethrough()
                newPricePerMonthText(for: introductoryOfferInfo.formattedIntroPricePerMonth)
                HStack(alignment: .bottom, spacing: TokenSpacing._2) {
                    Text(formattedPriceForYearlyPlan)
                        .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                        .font(.footnote)
                        .strikethrough()
                    Text(introductoryOfferInfo.formattedIntroPrice)
                        .font(.title3.bold())
                }
                chargedYearlyText
            } else {
                newPricePerMonthText(for: formattedMonthlyPriceForYearlyPlan)
                Text(formattedPriceForYearlyPlan)
                    .font(.title3.bold())
                chargedYearlyText
            }
        }
    }

    private var monthlyPriceView: some View {
        VStack(alignment: .trailing) {
            if let introductoryOfferInfo = viewModel.introductoryOfferInfo() {
                Text(introductoryOfferInfo.formattedFullPrice)
                    .font(.caption)
                    .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                    .strikethrough()
                Text(introductoryOfferInfo.formattedIntroPrice)
                    .font(.title2.bold())
            } else {
                Text(viewModel.plan.formattedPrice)
                    .font(.title2.bold())
            }
            Text(Strings.Localizable.productPricePerMonth(viewModel.plan.currency))
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private func attributedPricePerMonth(for formattedMonthlyPrice: String) -> AttributedString {
        let price = formattedMonthlyPrice
        let pricePerMonth = Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerMonth(formattedMonthlyPrice)

        guard let priceRange = pricePerMonth.range(of: price) else {
            var fallback = AttributedString(pricePerMonth)
            setFootNoteAndSecondaryColor(for: &fallback)
            return fallback
        }

        let suffixSubstring = pricePerMonth[priceRange.upperBound...]

        var pricePart = AttributedString(price)
        pricePart.font = .preferredFont(style: .title2, weight: .bold)
        pricePart.foregroundColor = TokenColors.Text.primary.swiftUI

        var suffixPart = AttributedString(String(suffixSubstring))
        setFootNoteAndSecondaryColor(for: &suffixPart)

        pricePart.append(suffixPart)
        return pricePart
    }

    private func newPricePerMonthText(for formattedMonthlyPrice: String) -> some View {
        Text(Strings.Localizable.UpgradeAccountPlan.Plan.Yearly.pricePerMonth(formattedMonthlyPrice))
            .foregroundColor(TokenColors.Text.brand.swiftUI)
            .font(.subheadline)
            .padding(.bottom, 6)
    }

    private var chargedYearlyText: Text {
        Text(Strings.Localizable.UpgradeAccountPlan.Plan.Yearly.footer)
            .font(.footnote)
            .foregroundColor(TokenColors.Text.secondary.swiftUI)
    }

    private func setFootNoteAndSecondaryColor(for attributedString: inout AttributedString) {
        attributedString.font = .preferredFont(style: .footnote, weight: .bold)
        attributedString.foregroundColor = TokenColors.Text.secondary.swiftUI
    }

    struct IntroductoryOfferYearlyPriceBottomView: View {
        let introductoryOfferInfo: IntroductoryOfferInfo

        var body: some View {
            Text(priceText)
                .font(.caption)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }

        private var priceText: AttributedString {
            var full = AttributedString(introductoryOfferInfo.formattedFullPrice)
            full.strikethroughStyle = .single

            full.append(AttributedString(" "))

            full.append(
                AttributedString(
                    Strings.Localizable.SubscriptionPurchase.Plan.firstYearOffer(
                        introductoryOfferInfo.formattedIntroPrice
                    )
                )
            )
            return full
        }
    }
}
