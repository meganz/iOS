@testable import Accounts
import Foundation
import MEGADomain
import MEGAPreferenceMocks
import Testing

@Suite("PromoDialogReshowAllowance")
struct PromoDialogReshowAllowanceTests {

    // MARK: - First showing

    @Test("An offer never shown on this account is available")
    func isAvailable_noRecord_returnsTrue() {
        let sut = makeSUT(offer: offer(campaignId: 2026, reshowTimeout: 3600))

        #expect(sut.isAvailable)
    }

    @Test("A record left by another campaign does not gate the current one")
    func isAvailable_recordFromAnotherCampaign_returnsTrue() {
        let preferenceUseCase = MockPreferenceUseCase()
        makeSUT(
            offer: offer(campaignId: 2026, reshowTimeout: nil),
            preferenceUseCase: preferenceUseCase
        ).consume()

        let sut = makeSUT(offer: offer(campaignId: 2027, reshowTimeout: nil), preferenceUseCase: preferenceUseCase)

        #expect(sut.isAvailable)
    }

    @Test("A campaign shown after another still holds the first one's showing against it")
    func isAvailable_afterASecondCampaignWasShown_stillGatesTheFirst() {
        let preferenceUseCase = MockPreferenceUseCase()
        let firstCampaign = makeSUT(
            offer: offer(campaignId: 2026, reshowTimeout: nil),
            preferenceUseCase: preferenceUseCase
        )
        firstCampaign.consume()

        makeSUT(
            offer: offer(campaignId: 2027, reshowTimeout: nil),
            preferenceUseCase: preferenceUseCase
        ).consume()

        #expect(firstCampaign.isAvailable == false)
    }

    // MARK: - Campaign identity

    @Test("Another offer from the same campaign spends the allowance the first one spent")
    func isAvailable_otherOfferFromTheSameCampaign_returnsFalse() {
        let preferenceUseCase = MockPreferenceUseCase()
        makeSUT(
            offer: offer(id: "black-friday-yearly", campaignId: 2026, reshowTimeout: nil),
            preferenceUseCase: preferenceUseCase
        ).consume()

        let sut = makeSUT(
            offer: offer(id: "black-friday-monthly", campaignId: 2026, reshowTimeout: nil),
            preferenceUseCase: preferenceUseCase
        )

        #expect(sut.isAvailable == false)
    }

    // MARK: - Reshow interval

    @Test("The same campaign is not shown again before its reshow interval has elapsed")
    func isAvailable_withinReshowInterval_returnsFalse() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let currentDate = MutableDate(now)
        let sut = makeSUT(offer: offer(campaignId: 2026, reshowTimeout: 3600), currentDate: currentDate.read)

        sut.consume()
        currentDate.value = now.addingTimeInterval(3599)

        #expect(sut.isAvailable == false)
    }

    @Test("The same campaign is shown again once its reshow interval has elapsed")
    func isAvailable_reshowIntervalElapsed_returnsTrue() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let currentDate = MutableDate(now)
        let sut = makeSUT(offer: offer(campaignId: 2026, reshowTimeout: 3600), currentDate: currentDate.read)

        sut.consume()
        currentDate.value = now.addingTimeInterval(3600)

        #expect(sut.isAvailable)
    }

    @Test("A campaign carrying no reshow interval is shown once only")
    func isAvailable_noReshowInterval_returnsFalseAfterFirstShowing() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let currentDate = MutableDate(now)
        let sut = makeSUT(offer: offer(campaignId: 2026, reshowTimeout: nil), currentDate: currentDate.read)

        sut.consume()
        currentDate.value = now.addingTimeInterval(60 * 60 * 24 * 365)

        #expect(sut.isAvailable == false)
    }

    // MARK: - Accounts

    @Test("Two accounts on the same device gate each other's dialog independently")
    func isAvailable_secondAccount_isNotGatedByTheFirst() {
        let preferenceUseCase = MockPreferenceUseCase()
        let campaign = offer(campaignId: 2026, reshowTimeout: nil)

        let firstAccount = makeSUT(offer: campaign, preferenceUseCase: preferenceUseCase, accountHandle: 1)
        firstAccount.consume()

        let secondAccount = makeSUT(offer: campaign, preferenceUseCase: preferenceUseCase, accountHandle: 2)

        #expect(firstAccount.isAvailable == false)
        #expect(secondAccount.isAvailable)
    }

    // MARK: - Storage

    @Test("A showing is stored under the key for this account and campaign")
    func consume_storesUnderTheAccountAndCampaignScopedKey() {
        let preferenceUseCase = MockPreferenceUseCase()
        let sut = makeSUT(
            offer: offer(campaignId: 2026, reshowTimeout: nil),
            preferenceUseCase: preferenceUseCase,
            accountHandle: 7
        )

        sut.consume()

        #expect(preferenceUseCase.dict["accounts.promoDialog.ShownDate-7-2026"] is Date)
    }

    @Test("Two campaigns shown to one account are stored side by side")
    func consume_twoCampaigns_storesBothUnderTheirOwnKeys() {
        let preferenceUseCase = MockPreferenceUseCase()

        for campaignId in [UInt64(2026), UInt64(2027)] {
            makeSUT(
                offer: offer(campaignId: campaignId, reshowTimeout: nil),
                preferenceUseCase: preferenceUseCase,
                accountHandle: 7
            ).consume()
        }

        #expect(preferenceUseCase.dict["accounts.promoDialog.ShownDate-7-2026"] is Date)
        #expect(preferenceUseCase.dict["accounts.promoDialog.ShownDate-7-2027"] is Date)
    }

    @Test("An allowance built later reads the showing an earlier one stored, so the key does not drift")
    func isAvailable_allowanceRebuiltForTheSameCampaign_seesTheStoredShowing() {
        let preferenceUseCase = MockPreferenceUseCase()
        let campaign = offer(campaignId: 2026, reshowTimeout: nil)
        makeSUT(offer: campaign, preferenceUseCase: preferenceUseCase).consume()

        let sut = makeSUT(offer: campaign, preferenceUseCase: preferenceUseCase)

        #expect(sut.isAvailable == false)
    }

    // MARK: - Helpers

    private func makeSUT(
        offer: MobileOfferEntity,
        preferenceUseCase: MockPreferenceUseCase = MockPreferenceUseCase(),
        accountHandle: HandleEntity = 1,
        currentDate: @escaping @Sendable () -> Date = { Date() }
    ) -> PromoDialogReshowAllowance {
        PromoDialogReshowAllowance(
            accountHandle: accountHandle,
            offer: offer,
            preferenceUseCase: preferenceUseCase,
            currentDate: currentDate
        )
    }

    private func offer(
        id: String = "black-friday-2026",
        campaignId: UInt64,
        reshowTimeout: TimeInterval?
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

/// A clock the test moves by hand, so crossing a reshow interval never depends on real time passing.
private final class MutableDate: @unchecked Sendable {
    private let lock = NSLock()
    private var date: Date

    init(_ date: Date) {
        self.date = date
    }

    var value: Date {
        get { lock.withLock { date } }
        set { lock.withLock { date = newValue } }
    }

    var read: @Sendable () -> Date {
        { [self] in value }
    }
}
