import Accounts
import MEGADesignToken
import MEGAL10n
import SwiftUI

struct SubscriptionPurchasePlanCardView: View {
    let viewModel: AccountPlanViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: TokenSpacing._3) {
            HStack {
                Text(viewModel.plan.name)
                    .font(.headline)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)

                if viewModel.planTag == .recommended {
                    Text(Strings.Localizable.UpgradeAccountPlan.Plan.Tag.recommended)
                        .font(.caption)
                        .foregroundStyle(TokenColors.Text.info.swiftUI)
                        .padding(.vertical, TokenSpacing._1)
                        .padding(.horizontal, TokenSpacing._3)
                        .background(TokenColors.Notifications.notificationInfo.swiftUI)
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
            yearlyPriceView
        }
    }

    private var yearlyPrice: String {
        viewModel.plan.formattedMonthlyPriceForYearlyPlan ?? ""
    }

    private var yearlyPriceView: some View {
        VStack(alignment: .trailing) {
            Text(attributedPricePerMonth)
            Text(Strings.Localizable.SubscriptionPurchase.Plan.billedYearly(viewModel.plan.formattedPrice))
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private var monthlyPriceView: some View {
        VStack(alignment: .trailing) {
            Text(viewModel.plan.formattedPrice)
                .font(.title2.bold())

            Text(Strings.Localizable.productPricePerMonth(viewModel.plan.currency))
                .font(.footnote)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        }
    }

    private var attributedPricePerMonth: AttributedString {
        let price = yearlyPrice
        let pricePerMonth = Strings.Localizable.UpgradeAccountPlan.Plan.Details.Pricing.localCurrencyPerMonth(yearlyPrice)

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

    private func setFootNoteAndSecondaryColor(for attributedString: inout AttributedString) {
        attributedString.font = .preferredFont(style: .footnote, weight: .bold)
        attributedString.foregroundColor = TokenColors.Text.secondary.swiftUI
    }
}
