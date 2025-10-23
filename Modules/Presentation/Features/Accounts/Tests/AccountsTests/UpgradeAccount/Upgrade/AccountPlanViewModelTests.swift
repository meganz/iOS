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
        func none() {
            let sut = makeSUT(planTag: .none)
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
        func introOfferWithDiscount_whenBlackFridayCampaignRange_shouldShowCorrectText() {
            let fakeNow = nzDate(2025, 11, 28, 0, 0, 0)
            let plan = discountedPlanUSD()
            let expected = Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.blackFridayDeal("20%")

            let sut = makeSUT(
                plan: plan,
                planTag: .introOffer,
                now: { fakeNow },
                calendar: nzCalendar,
                timeZone: nzTimeZone
            )

            #expect(sut.planBadge?.text == expected)
        }

        @Test
        @MainActor
        func introOfferWithDiscount_whenNotBlackFridayCampaignRange_shouldShowCorrectText() {
            let year = 2025
            let fakeNow = nzDate(year, 12, 8, 0, 0, 0)
            let plan = discountedPlanUSD()
            let expected = Strings.Localizable.UpgradeAccountPlan.Plan.Tag.IntroOffer.generalDeal("20%")

            let sut = makeSUT(
                plan: plan,
                planTag: .introOffer,
                now: { fakeNow },
                calendar: nzCalendar,
                timeZone: nzTimeZone
            )

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
        planTag: AccountPlanTagEntity = .none,
        isSelected: Bool = false,
        isSelectionEnabled: Bool = true,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = Calendar.current,
        timeZone: TimeZone = TimeZone.current,
        didTapPlan: @escaping () -> Void = {}
    ) -> AccountPlanViewModel {
        .init(
            plan: plan,
            planTag: planTag,
            isSelected: isSelected,
            isSelectionEnabled: isSelectionEnabled,
            now: now,
            calendar: calendar,
            timeZone: timeZone,
            didTapPlan: didTapPlan
        )
    }

    private static let nzTimeZone = TimeZone(identifier: "Pacific/Auckland")!
    private static let nzCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = nzTimeZone
        return cal
    }()

    private static func nzDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day
        comps.hour = hour; comps.minute = minute; comps.second = second
        comps.timeZone = nzTimeZone
        return nzCalendar.date(from: comps)!
    }

    private static func discountedPlanUSD() -> PlanEntity {
        PlanEntity(
            type: .proI,
            subscriptionCycle: .yearly,
            appStorePrice: .init(price: 100, formattedPrice: "$100", currency: "USD"),
            introductoryOffer: IntroductoryOfferEntity(
                price: 80, // 20% off
                period: .init(unit: .year, value: 1),
                periodCount: 1
            )
        )
    }
}
