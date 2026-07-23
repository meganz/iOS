@testable import Accounts
import Foundation
import MEGADomain
import MEGAFoundation
import MEGAL10n
import Testing

@Suite("SubscriptionCurrentPlanViewModel - cycleText & statusText")
struct SubscriptionCurrentPlanViewModelTests {

    private func mediumString(_ date: Date) -> String {
        DateFormatter.dateMedium().localisedString(from: date)
    }

    private func weekdayString(_ date: Date) -> String {
        DateFormatter.dateMediumWithWeekday().localisedString(from: date)
    }

    // MARK: - cycleText

    @Test("Monthly cycle shows the monthly label - \"Monthly subscription\"")
    func monthlyCycleText() {
        let sut = SubscriptionCurrentPlanViewModel(name: "Pro I", cycle: .monthly)
        #expect(sut.cycleText == Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.monthly)
    }

    @Test("Yearly cycle shows the yearly label - \"Yearly subscription\"")
    func yearlyCycleText() {
        let sut = SubscriptionCurrentPlanViewModel(name: "Pro I", cycle: .yearly)
        #expect(sut.cycleText == Strings.Localizable.SubscriptionPurchase.Revamp.Cycle.yearly)
    }

    @Test("One-off (no cycle) has no cycle text - nil")
    func noneCycleText() {
        let sut = SubscriptionCurrentPlanViewModel(name: "Pro I", cycle: .none)
        #expect(sut.cycleText == nil)
    }

    // MARK: - statusText (absent)

    @Test("No status yields no status text - nil")
    func noStatusText() {
        let sut = SubscriptionCurrentPlanViewModel(name: "Pro I", cycle: .yearly, status: nil)
        #expect(sut.statusText == nil)
    }

    // MARK: - statusText (.renews)

    @Test("Renews today - \"Renews today\"")
    func renewsToday() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let sut = SubscriptionCurrentPlanViewModel(name: "Pro I", cycle: .yearly, status: .renews(now), now: now)
        #expect(sut.statusText == Strings.Localizable.Account.Profile.Renewal.today)
    }

    @Test("Renews tomorrow - \"Renews tomorrow\"")
    func renewsTomorrow() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let tomorrow = try #require(Calendar.current.date(byAdding: .day, value: 1, to: now))
        let sut = SubscriptionCurrentPlanViewModel(name: "Pro I", cycle: .yearly, status: .renews(tomorrow), now: now)
        #expect(sut.statusText == Strings.Localizable.Account.Profile.Renewal.tomorrow)
    }

    @Test("Renews on a near date (within a week) uses the weekday date format - \"Renews on %@\"")
    func renewsNearFuture() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let date = try #require(Calendar.current.date(byAdding: .day, value: 3, to: now))
        let sut = SubscriptionCurrentPlanViewModel(name: "Pro I", cycle: .yearly, status: .renews(date), now: now)
        #expect(sut.statusText == Strings.Localizable.Account.Profile.Renewal.future(weekdayString(date)))
    }

    @Test("Renews on a far date uses the medium date format - \"Renews on %@\"")
    func renewsFarFuture() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let date = try #require(Calendar.current.date(byAdding: .day, value: 60, to: now))
        let sut = SubscriptionCurrentPlanViewModel(name: "Pro I", cycle: .yearly, status: .renews(date), now: now)
        #expect(sut.statusText == Strings.Localizable.Account.Profile.Renewal.future(mediumString(date)))
    }

    // MARK: - statusText (.expires)

    @Test("Expires on a far date uses the medium date format - \"Expires on %@\"")
    func expiresFarFuture() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let date = try #require(Calendar.current.date(byAdding: .day, value: 60, to: now))
        let sut = SubscriptionCurrentPlanViewModel(name: "Pro I", cycle: .none, status: .expires(date), now: now)
        #expect(sut.statusText == Strings.Localizable.Account.Profile.Expiry.future(mediumString(date)))
    }

    @Test("Expires today has no today/tomorrow special-casing, uses the date - \"Expires on %@\"")
    func expiresTodayUsesDate() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let sut = SubscriptionCurrentPlanViewModel(name: "Pro I", cycle: .none, status: .expires(now), now: now)
        #expect(sut.statusText == Strings.Localizable.Account.Profile.Expiry.future(weekdayString(now)))
    }
}
