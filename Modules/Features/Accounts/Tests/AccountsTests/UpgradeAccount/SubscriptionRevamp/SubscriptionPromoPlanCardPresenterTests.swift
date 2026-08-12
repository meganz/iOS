@testable import Accounts
import MEGADomain
import MEGAL10n
import Testing

@Suite("SubscriptionPromoPlanCardPresenter - featured plan card")
struct SubscriptionPromoPlanCardPresenterTests {

    private func makeSUT(
        storage: String = "2 TB",
        transfer: String = "2 TB"
    ) -> SubscriptionPromoPlanCardPresenter {
        SubscriptionPromoPlanCardPresenter(
            plan: PlanEntity(
                productIdentifier: "pro1.oneMonth",
                type: .proI,
                subscriptionCycle: .monthly,
                storage: storage,
                transfer: transfer
            ),
            displayName: { $0.toAccountTypeDisplayName() }
        )
    }

    @Test("Maps the plan's identifier and title")
    func mapsIdentifierAndTitle() {
        let name = AccountTypeEntity.proI.toAccountTypeDisplayName()
        let card = makeSUT().cardModel
        #expect(card.productIdentifier == "pro1.oneMonth")
        #expect(card.title == name)
        #expect(card.buttonTitle == Strings.Localizable.SubscriptionPurchase.Button.getPlan(name))
    }

    @Test("Storage and transfer are labelled, not raw plan values")
    func labelsStorageAndTransfer() {
        let card = makeSUT(storage: "8 TB", transfer: "8 TB").cardModel
        #expect(card.storage == Strings.Localizable.SubscriptionPurchase.Plan.storage("8 TB"))
        #expect(card.transfer == Strings.Localizable.SubscriptionPurchase.Plan.transfer("8 TB"))
        #expect(card.storage != "8 TB")
        #expect(card.transfer != "8 TB")
    }
}
