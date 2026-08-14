@testable import Accounts
import Foundation
import MEGADomain
import MEGAPreference
import Testing

/// The QA store reads the suite the allowance writes into, so these tests drive it through a real allowance over a
/// throwaway `UserDefaults` suite rather than a mock: the keys are the contract between the two.
@Suite("PromoDialogReshowQAStore")
struct PromoDialogReshowQAStoreTests {

    // MARK: - Listing

    @Test("Every campaign shown to this account is listed with the date it was shown")
    func storedRecordDescriptions_afterTwoCampaigns_listsBoth() throws {
        try withSuite(named: "listsBoth") { userDefaults in
            let now = Date(timeIntervalSince1970: 1_000_000)
            for campaignId in [UInt64(2026), UInt64(2027)] {
                makeAllowance(
                    userDefaults: userDefaults,
                    offer: offer(campaignId: campaignId),
                    currentDate: { now }
                ).consume()
            }

            let sut = PromoDialogReshowQAStore(accountHandle: 1, userDefaults: userDefaults)

            #expect(sut.storedRecordDescriptions == [
                "2026 @ \(now.formatted())",
                "2027 @ \(now.formatted())"
            ])
        }
    }

    @Test("An account the dialog has never been shown to lists nothing")
    func storedRecordDescriptions_noShowings_isEmpty() throws {
        try withSuite(named: "isEmpty") { userDefaults in
            makeAllowance(
                userDefaults: userDefaults,
                offer: offer(campaignId: 2026),
                accountHandle: 1
            ).consume()

            let sut = PromoDialogReshowQAStore(accountHandle: 2, userDefaults: userDefaults)

            #expect(sut.storedRecordDescriptions.isEmpty)
        }
    }

    // MARK: - Editing

    @Test("Resetting forgets every campaign shown to this account")
    func reset_afterTwoCampaigns_makesBothAvailableAgain() throws {
        try withSuite(named: "reset") { userDefaults in
            let allowances = [UInt64(2026), UInt64(2027)].map {
                makeAllowance(userDefaults: userDefaults, offer: offer(campaignId: $0))
            }
            allowances.forEach { $0.consume() }

            PromoDialogReshowQAStore(accountHandle: 1, userDefaults: userDefaults).reset()

            #expect(allowances.allSatisfy { $0.isAvailable })
        }
    }

    @Test("Resetting leaves another account's showings alone")
    func reset_anotherAccountsShowing_isUntouched() throws {
        try withSuite(named: "resetOtherAccount") { userDefaults in
            let otherAccount = makeAllowance(
                userDefaults: userDefaults,
                offer: offer(campaignId: 2026),
                accountHandle: 2
            )
            otherAccount.consume()

            PromoDialogReshowQAStore(accountHandle: 1, userDefaults: userDefaults).reset()

            #expect(otherAccount.isAvailable == false)
        }
    }

    @Test("Backdating the stored showings crosses the reshow interval without waiting")
    func backdateShownDates_pastTheInterval_makesTheCampaignAvailableAgain() throws {
        try withSuite(named: "backdate") { userDefaults in
            let now = Date(timeIntervalSince1970: 1_000_000)
            let allowance = makeAllowance(
                userDefaults: userDefaults,
                offer: offer(campaignId: 2026, reshowTimeout: 3600),
                currentDate: { now }
            )
            allowance.consume()

            PromoDialogReshowQAStore(accountHandle: 1, userDefaults: userDefaults).backdateShownDates(by: 3600)

            #expect(allowance.isAvailable)
        }
    }

    // MARK: - Helpers

    /// Runs `body` against a suite of its own, wiped before and after, so tests running side by side never read
    /// each other's showings and nothing survives the run.
    private func withSuite(named name: String, _ body: (UserDefaults) throws -> Void) throws {
        let suiteName = "PromoDialogReshowQAStoreTests-\(name)"
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

        try body(try #require(UserDefaults(suiteName: suiteName)))
    }

    private func makeAllowance(
        userDefaults: UserDefaults,
        offer: MobileOfferEntity,
        accountHandle: HandleEntity = 1,
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) -> PromoDialogReshowAllowance {
        PromoDialogReshowAllowance(
            accountHandle: accountHandle,
            offer: offer,
            preferenceUseCase: PreferenceUseCase(repository: PreferenceRepository(userDefaults: userDefaults)),
            currentDate: currentDate
        )
    }

    private func offer(
        id: String = "black-friday-2026",
        campaignId: UInt64,
        reshowTimeout: TimeInterval? = nil
    ) -> MobileOfferEntity {
        MobileOfferEntity(
            id: id,
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 1,
            reshowTimeout: reshowTimeout,
            expiryDate: nil,
            iosOfferId: nil,
            iosSignature: nil,
            campaignId: campaignId
        )
    }
}
