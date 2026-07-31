@testable import Accounts
import MEGADomain
import Testing

@Suite("SubscriptionProFeaturesViewModel")
struct SubscriptionProFeaturesViewModelTests {

    private func plan(
        storageLimit: Int = 0,
        transferLimit: Int = 0,
        storage: String = "",
        transfer: String = ""
    ) -> PlanEntity {
        PlanEntity(
            type: .proI,
            subscriptionCycle: .monthly,
            storageLimit: storageLimit,
            transferLimit: transferLimit,
            storage: storage,
            transfer: transfer
        )
    }

    private func makeSUT(plans: [PlanEntity]) -> SubscriptionProFeaturesViewModel {
        SubscriptionProFeaturesViewModel(plans: plans)
    }

    @Test("Storage comes from the plan with the highest storage limit")
    func storageUsesHighestLimit() {
        let sut = makeSUT(plans: [
            plan(storageLimit: 400, storage: "400 GB"),
            plan(storageLimit: 16384, storage: "16 TB"),
            plan(storageLimit: 2048, storage: "2 TB")
        ])
        #expect(sut.maxPlanStorage == "16 TB")
    }

    @Test("Transfer comes from the plan with the highest transfer limit")
    func transferUsesHighestLimit() {
        let sut = makeSUT(plans: [
            plan(transferLimit: 400, transfer: "400 GB"),
            plan(transferLimit: 16384, transfer: "16 TB"),
            plan(transferLimit: 2048, transfer: "2 TB")
        ])
        #expect(sut.maxPlanTransfer == "16 TB")
    }

    @Test("Storage and transfer are resolved independently of each other")
    func storageAndTransferResolvedIndependently() {
        let sut = makeSUT(plans: [
            plan(storageLimit: 16384, transferLimit: 100, storage: "16 TB", transfer: "100 GB"),
            plan(storageLimit: 100, transferLimit: 16384, storage: "100 GB", transfer: "16 TB")
        ])
        #expect(sut.maxPlanStorage == "16 TB")
        #expect(sut.maxPlanTransfer == "16 TB")
    }

    @Test("A single plan is used regardless of its limits")
    func singlePlanIsUsed() {
        let sut = makeSUT(plans: [
            plan(storageLimit: 1, transferLimit: 1, storage: "1 GB", transfer: "2 GB")
        ])
        #expect(sut.maxPlanStorage == "1 GB")
        #expect(sut.maxPlanTransfer == "2 GB")
    }

    @Test("No plans falls back to the default copy")
    func noPlansFallsBackToDefaults() {
        let sut = makeSUT(plans: [])
        #expect(sut.maxPlanStorage == "20 TB")
        #expect(sut.maxPlanTransfer == "240 TB")
    }

    @Test("Plans with equal limits resolve to a value present in the list")
    func equalLimitsResolveToAListedValue() {
        let sut = makeSUT(plans: [
            plan(storageLimit: 2048, storage: "2 TB"),
            plan(storageLimit: 2048, storage: "2 TB")
        ])
        #expect(sut.maxPlanStorage == "2 TB")
    }
}
