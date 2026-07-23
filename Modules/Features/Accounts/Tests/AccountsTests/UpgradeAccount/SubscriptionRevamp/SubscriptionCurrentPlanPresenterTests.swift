@testable import Accounts
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Testing

@Suite("SubscriptionCurrentPlanPresenter - current plan card derivation")
struct SubscriptionCurrentPlanPresenterTests {

    private func makeSUT(
        _ accountDetails: AccountDetailsEntity,
        plans: [PlanEntity] = [],
        now: Date = Date(),
        displayName: @Sendable @escaping (AccountTypeEntity) -> String = { $0.toAccountTypeDisplayName() }
    ) -> SubscriptionCurrentPlanPresenter {
        SubscriptionCurrentPlanPresenter(accountDetails: accountDetails, plans: plans, displayName: displayName, now: now)
    }

    @Test("Free account shows no current-plan card")
    func freeAccountHasNoCard() {
        let sut = makeSUT(.build(proLevel: .free))
        #expect(sut.currentPlanViewModel == nil)
    }

    @Test("Uses the matched product plan's name")
    func usesMatchedPlanName() throws {
        let sut = makeSUT(
            .build(proLevel: .proI, subscriptionRenewTime: 1_000, subscriptionCycle: .yearly),
            plans: [PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly)]
        )
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.name == "Pro I")
    }

    @Test("Falls back to the account-type display name when the plan is not in the product list")
    func fallsBackToDisplayName() throws {
        let sut = makeSUT(.build(proLevel: .proII, subscriptionRenewTime: 1_000), plans: [])
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.name == AccountTypeEntity.proII.toAccountTypeDisplayName())
    }

    @Test("Renewable subscription maps to .renews with the renewal date")
    func renewableUsesRenewTime() throws {
        let renewTime = 1_814_000_000
        let sut = makeSUT(.build(proLevel: .proI, subscriptionRenewTime: renewTime, subscriptionCycle: .yearly))
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.status == .renews(Date(timeIntervalSince1970: TimeInterval(renewTime))))
        #expect(vm.cycle == .yearly)
    }

    @Test("One-off plan maps to .expires with the expiry date and no cycle text")
    func oneOffUsesExpiration() throws {
        let expiry = 1_814_000_000
        let sut = makeSUT(.build(proLevel: .proI, proExpiration: expiry, subscriptionCycle: .none))
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.status == .expires(Date(timeIntervalSince1970: TimeInterval(expiry))))
        #expect(vm.cycleText == nil)
    }

    @Test("No renewal or expiration timestamp yields no status line")
    func noTimestampsHasNoStatus() throws {
        let sut = makeSUT(.build(proLevel: .proI, proExpiration: 0, subscriptionRenewTime: 0))
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.status == nil)
        #expect(vm.statusText == nil)
    }

    @Test("Renewal time takes precedence over expiration when both are present")
    func renewTakesPrecedenceOverExpiration() throws {
        let renewTime = 1_800_000_000
        let expiry = 1_700_000_000
        let sut = makeSUT(.build(proLevel: .proI, proExpiration: expiry, subscriptionRenewTime: renewTime))
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.status == .renews(Date(timeIntervalSince1970: TimeInterval(renewTime))))
    }

    @Test("Cycle is taken from account details, not the matched plan")
    func cycleComesFromAccountDetails() throws {
        let sut = makeSUT(
            .build(proLevel: .proI, subscriptionRenewTime: 1_000, subscriptionCycle: .monthly),
            plans: [PlanEntity(type: .proI, name: "Pro I", subscriptionCycle: .yearly)]
        )
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.cycle == .monthly)
    }

    @Test("makeCurrentPlan(for:in:) returns nil for a free account")
    func staticCurrentPlanNilForFree() {
        #expect(SubscriptionCurrentPlanPresenter.makeCurrentPlan(
            for: .build(proLevel: .free),
            in: [],
            displayName: { $0.toAccountTypeDisplayName() }
        ) == nil)
    }

    // MARK: - badgeTitle (Expiring)

    private let referenceNow = Date(timeIntervalSince1970: 1_800_000_000)

    private func expiry(_ component: Calendar.Component, _ value: Int, from base: Date) throws -> Int64 {
        let date = try #require(Calendar.current.date(byAdding: component, value: value, to: base))
        return Int64(date.timeIntervalSince1970)
    }

    private func account(cycle: SubscriptionCycleEntity, expirationTime: Int64) -> AccountDetailsEntity {
        .build(
            proLevel: .proI,
            subscriptionCycle: cycle,
            plans: [.init(accountType: .proI, expirationTime: expirationTime)]
        )
    }

    @Test("One-off plan expiring within one month shows the Expiring badge")
    func oneOffExpiringWithinMonthShowsBadge() throws {
        let sut = makeSUT(account(cycle: .none, expirationTime: try expiry(.day, 30, from: referenceNow)), now: referenceNow)
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.badgeTitle == Strings.Localizable.SubscriptionPurchase.Revamp.Badge.expiring)
    }

    @Test("One-off plan expiring more than one month away shows no badge")
    func oneOffExpiringBeyondMonthHasNoBadge() throws {
        let oneMonth = try #require(Calendar.current.date(byAdding: .month, value: 1, to: referenceNow))
        let sut = makeSUT(account(cycle: .none, expirationTime: try expiry(.day, 5, from: oneMonth)), now: referenceNow)
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.badgeTitle == nil)
    }

    @Test("One-off plan already expired shows no badge")
    func oneOffAlreadyExpiredHasNoBadge() throws {
        let sut = makeSUT(account(cycle: .none, expirationTime: try expiry(.day, -15, from: referenceNow)), now: referenceNow)
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.badgeTitle == nil)
    }

    @Test("One-off plan with no expiration timestamp shows no badge")
    func oneOffWithoutExpirationHasNoBadge() throws {
        let sut = makeSUT(account(cycle: .none, expirationTime: 0), now: referenceNow)
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.badgeTitle == nil)
    }

    @Test("Recurring plan expiring within one month shows no badge (deferred to IOS-12270)", arguments: [
        SubscriptionCycleEntity.monthly,
        SubscriptionCycleEntity.yearly
    ])
    func recurringExpiringWithinMonthHasNoBadge(cycle: SubscriptionCycleEntity) throws {
        let sut = makeSUT(account(cycle: cycle, expirationTime: try expiry(.day, 15, from: referenceNow)), now: referenceNow)
        let vm = try #require(sut.currentPlanViewModel)
        #expect(vm.badgeTitle == nil)
    }
}
