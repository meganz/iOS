@testable import Accounts
import Foundation
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

@Suite("MenuDiscountBannerContentMapper")
struct MenuDiscountBannerContentMapperTests {
    @Suite("No content")
    struct NoContent {
        @Test("Maps to nil when the plan carries no discount")
        func nilForUndiscountedMonthlyPrice() {
            let sut = makeSUT(planPrice: .monthly(.init(price: 9.99, currency: "EUR")))

            #expect(sut.map(.menuBannerPlan()) == nil)
        }

        @Test("Maps to nil when the plan carries no discount on a yearly price")
        func nilForUndiscountedYearlyPrice() {
            let sut = makeSUT(planPrice: .yearly(.init(price: 99.99, currency: "EUR")))

            #expect(sut.map(.menuBannerPlan()) == nil)
        }

        @Test("Maps to nil when the discount is zero percent")
        func nilForZeroPercentDiscount() {
            let sut = makeSUT(planPrice: .discounted(percentage: 0))

            #expect(sut.map(.menuBannerPlan()) == nil)
        }
    }

    @Suite("Message")
    struct Message {
        @Test("Builds the message from the campaign label, discount, monthly price and plan name")
        func buildsMessageFromOffer() throws {
            let sut = makeSUT(planPrice: .discounted(percentage: 50, pricePerMonth: 4.99))
            let plan = PlanEntity.menuBannerPlan(label: "Black Friday", introductoryOffer: .stub)

            let content = try #require(sut.map(plan))

            #expect(content.message == Strings.Localizable.Home.PromotionalBanners.DiscountBanner.message(
                "Black Friday",
                "50%",
                "€4.99",
                "Pro I"
            ))
        }

        @Test("Falls back to the generic offer label when the campaign has no label")
        func fallsBackToSpecialOfferLabel() throws {
            let sut = makeSUT(planPrice: .discounted(percentage: 30, pricePerMonth: 6.99))
            let plan = PlanEntity.menuBannerPlan(label: nil, introductoryOffer: .stub)

            let content = try #require(sut.map(plan))

            #expect(content.message == Strings.Localizable.Home.PromotionalBanners.DiscountBanner.message(
                Strings.Localizable.SubscriptionPurchase.Revamp.Promo.specialOffer,
                "30%",
                "€6.99",
                "Pro I"
            ))
        }

        @Test("Falls back to the generic offer label when the campaign label is empty")
        func fallsBackForEmptyLabel() throws {
            let sut = makeSUT(planPrice: .discounted(percentage: 30, pricePerMonth: 6.99))
            let plan = PlanEntity.menuBannerPlan(label: "", introductoryOffer: .stub)

            let content = try #require(sut.map(plan))

            #expect(content.message.hasPrefix(Strings.Localizable.SubscriptionPurchase.Revamp.Promo.specialOffer))
        }

        @Test("Falls back to the generic offer label when no offer applies to the plan")
        func fallsBackWhenNoOfferApplies() throws {
            let sut = makeSUT(planPrice: .discounted(percentage: 30, pricePerMonth: 6.99))
            let plan = PlanEntity.menuBannerPlan(label: "Black Friday")

            let content = try #require(sut.map(plan))

            #expect(content.message.hasPrefix(Strings.Localizable.SubscriptionPurchase.Revamp.Promo.specialOffer))
        }

        @Test("Always uses the shared grab deal action title")
        func usesGrabDealActionTitle() throws {
            let sut = makeSUT(planPrice: .discounted(percentage: 50))

            let content = try #require(sut.map(.menuBannerPlan()))

            #expect(content.actionTitle == Strings.Localizable.Home.PromotionalBanners.DiscountBanner.grabDeal)
        }
    }

    @Suite("Countdown deadline")
    struct Deadline {
        @Test("Uses the offer expiry for a signed promotional offer")
        func usesExpiryForValidPromotionalOffer() throws {
            let sut = makeSUT(planPrice: .discounted(percentage: 50))
            let plan = PlanEntity.menuBannerPlan(
                expiryDate: expiry,
                iosSignature: .stub,
                promotionalOffer: .stub
            )

            let content = try #require(sut.map(plan))

            #expect(content.deadline == expiry)
        }

        @Test("Has no deadline when the plan carries no promotional offer")
        func noDeadlineWithoutPromotionalOffer() throws {
            let sut = makeSUT(planPrice: .discounted(percentage: 50))
            let plan = PlanEntity.menuBannerPlan(expiryDate: expiry, iosSignature: .stub)

            let content = try #require(sut.map(plan))

            #expect(content.deadline == nil)
        }

        @Test("Has no deadline when the promotional offer is unsigned")
        func noDeadlineWithoutSignature() throws {
            let sut = makeSUT(planPrice: .discounted(percentage: 50))
            let plan = PlanEntity.menuBannerPlan(expiryDate: expiry, promotionalOffer: .stub)

            let content = try #require(sut.map(plan))

            #expect(content.deadline == nil)
        }

        @Test("Has no deadline for an introductory offer, which carries no expiry")
        func noDeadlineForIntroductoryOffer() throws {
            let sut = makeSUT(planPrice: .discounted(percentage: 50))
            let plan = PlanEntity.menuBannerPlan(introductoryOffer: .stub)

            let content = try #require(sut.map(plan))

            #expect(content.deadline == nil)
        }
    }
}

private let expiry = Date(timeIntervalSince1970: 1_800_000_000)

private func makeSUT(planPrice: SubscriptionPlanPrice) -> MenuDiscountBannerContentMapper {
    .stub(planPrice: planPrice)
}
