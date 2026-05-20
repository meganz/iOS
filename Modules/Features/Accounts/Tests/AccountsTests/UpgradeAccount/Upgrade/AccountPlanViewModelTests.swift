@testable import Accounts
import Foundation
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAUIComponent
import Testing

struct AccountPlanViewModelTests {
    @Suite("Plan Badge")
    struct PlanBadge {
        @Test
        @MainActor
        func currentPlan() {
            let sut = makeSUT(planTag: .currentPlan)
            #expect(sut.planBadge?.type == .warning)
            #expect(sut.planBadge?.text == Strings.Localizable.UpgradeAccountPlan.Plan.Tag.currentPlan)
        }
        
        @Test
        @MainActor
        func recommended() {
            let sut = makeSUT(planTag: .recommended)
            #expect(sut.planBadge?.type == .infoPrimary)
            #expect(sut.planBadge?.text == Strings.Localizable.UpgradeAccountPlan.Plan.Tag.recommended)
        }
        
        @Test
        @MainActor
        func noTag() {
            let sut = makeSUT(planTag: .noTag)
            #expect(sut.planBadge == nil)
        }
        
        @Test
        @MainActor
        func introOfferWithoutDiscount() {
            let plan = PlanEntity(
                type: .proI,
                subscriptionCycle: .yearly,
                introductoryOffer: nil
            )
            let sut = makeSUT(plan: plan, planTag: .introOffer)
            #expect(sut.planBadge == nil)
        }

        @Test
        @MainActor
        func introOfferWithDiscount_withBlackFridayMobileOfferLabel_shouldShowSpecialOfferLabel() {
            let plan = discountedPlanEntity(mobileOfferLabel: "Black Friday deal")
            let expected = Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOfferLabel("Black Friday deal", "20%")

            let sut = makeSUT(plan: plan, planTag: .introOffer)

            #expect(sut.planBadge?.text == expected)
        }

        @Test
        @MainActor
        func introOfferWithDiscount_withCyberMondayMobileOfferLabel_shouldShowSpecialOfferLabel() {
            let plan = discountedPlanEntity(mobileOfferLabel: "Cyber Monday deal")
            let expected = Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOfferLabel("Cyber Monday deal", "20%")

            let sut = makeSUT(plan: plan, planTag: .introOffer)

            #expect(sut.planBadge?.text == expected)
        }

        @Test
        @MainActor
        func introOfferWithDiscount_withCustomMobileOfferLabel_shouldShowSpecialOfferLabel() {
            let plan = discountedPlanEntity(mobileOfferLabel: "Easter Sale")
            let expected = Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOfferLabel("Easter Sale", "20%")

            let sut = makeSUT(plan: plan, planTag: .introOffer)

            #expect(sut.planBadge?.text == expected)
        }

        @Test
        @MainActor
        func introOfferWithDiscount_withoutMobileOfferLabel_shouldShowSpecialOffer() {
            let plan = discountedPlanEntity()
            let expected = Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOffer("20%")

            let sut = makeSUT(plan: plan, planTag: .introOffer)

            #expect(sut.planBadge?.text == expected)
        }

        @Test
        @MainActor
        func introOfferWithDiscount_withEmptyMobileOfferLabel_shouldShowSpecialOffer() {
            let plan = discountedPlanEntity(mobileOfferLabel: "")
            let expected = Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.specialOffer("20%")

            let sut = makeSUT(plan: plan, planTag: .introOffer)

            #expect(sut.planBadge?.text == expected)
        }
    }
    
    @Suite("Introductory Offer Info")
    struct IntroductoryOfferInfo {
        @MainActor
        @Test
        func yearlyPlanWithIntroOffer() {
            let introOffer = IntroductoryOfferEntity(
                price: 50,
                period: .init(unit: .year, value: 1),
                periodCount: 1
            )
            let plan = PlanEntity(
                type: .proI,
                subscriptionCycle: .yearly,
                appStorePrice: .init(price: 100, formattedPrice: "$100", currency: "USD"),
                introductoryOffer: introOffer
            )
            let sut = makeSUT(plan: plan)
            
            let info = sut.introductoryOfferInfo()

            #expect(info != nil)
            #expect(info?.fullPrice == 100)
            #expect(info?.introPrice == 50)
            #expect(info?.period.unit == .year)
            #expect(info?.period.value == 1)
        }
        
        @Test
        @MainActor
        func monthlyPlanWithIntroOffer() {
            let introOffer = IntroductoryOfferEntity(
                price: 8,
                period: .init(unit: .month, value: 1),
                periodCount: 1
            )
            let plan = PlanEntity(
                type: .proI,
                subscriptionCycle: .monthly,
                appStorePrice: .init(price: 10, formattedPrice: "$10", currency: "USD"),
                introductoryOffer: introOffer
            )
            let sut = makeSUT(plan: plan)
            
            let info = sut.introductoryOfferInfo()
            #expect(info != nil)
            #expect(info?.fullPrice == 10)
            #expect(info?.introPrice == 8)
            #expect(info?.period.unit == .month)
            #expect(info?.period.value == 1)
        }
        
        @Test
        @MainActor
        func planWithoutIntroOffer() {
            let plan = PlanEntity(
                type: .proI,
                subscriptionCycle: .yearly,
                introductoryOffer: nil
            )
            let sut = makeSUT(plan: plan)
            
            let info = sut.introductoryOfferInfo()
            #expect(info == nil)
        }
    }

    @MainActor
    private static func makeSUT(
        plan: PlanEntity = .init(),
        planTag: AccountPlanTagEntity = .noTag,
        isSelected: Bool = false,
        isSelectionEnabled: Bool = true,
        didTapPlan: @escaping () -> Void = {}
    ) -> AccountPlanViewModel {
        .init(
            plan: plan,
            planTag: planTag,
            isSelected: isSelected,
            isSelectionEnabled: isSelectionEnabled,
            isNewYearlyPlanStyleEnabled: true,
            didTapPlan: didTapPlan
        )
    }

    private static func discountedPlanEntity(mobileOfferLabel: String? = nil) -> PlanEntity {
        PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: 100, formattedPrice: "$100", currency: "USD"),
            introductoryOffer: IntroductoryOfferEntity(
                price: 80, // 20% off
                period: .init(unit: .year, value: 1),
                periodCount: 1
            ),
            mobileOfferLabel: mobileOfferLabel
        )
    }
}
