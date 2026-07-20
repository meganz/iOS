import MEGADomain
import MEGADomainMock
import MEGAUIComponent
import Testing
@testable import QuotaWarnings

private extension QuotaDialogHeader {
    var storageHeader: StorageQuotaHeader? {
        if case let .storage(header) = self { header } else { nil }
    }
    var transferHeader: TransferQuotaHeader? {
        if case let .transfer(header) = self { header } else { nil }
    }
}

@Suite("Storage quota dialog mapper")
struct StorageQuotaDialogMapperTests {
    private func recommendedEntity() -> RecommendedUpgradePlanEntity {
        RecommendedUpgradePlanEntity(
            name: "Essential",
            storage: "200 GB",
            storageLimit: 200,
            transfer: "2 TB",
            transferLimit: 2048,
            mobileOfferLabel: nil,
            price: .yearly(.init(price: 40, currency: "EUR"))
        )
    }

    @Test func header_almostFull_showsPercentAndAlmostFullCopy() throws {
        let sut = StorageQuotaDialogMapper(severity: .almostFull)
        let header = try #require(sut.header(accountDetails: .build(storageUsed: 90, storageMax: 100)).storageHeader)

        #expect(header.title == "Your storage is 90% full")
        #expect(header.subtitle == "Upgrade your plan before you run out of space")
    }

    @Test func header_full_showsFullCopy() throws {
        let sut = StorageQuotaDialogMapper(severity: .full)
        let header = try #require(sut.header(accountDetails: .build(storageUsed: 100, storageMax: 100)).storageHeader)

        #expect(header.title == "Your storage is 100% full")
        #expect(header.subtitle == "Upgrade your plan to get more storage and upload more files")
    }

    @Test func currentPlan_usesStorageUsageAndSeverityStatus() {
        let sut = StorageQuotaDialogMapper(severity: .full)
        let currentPlan = sut.currentPlan(accountDetails: .build(storageUsed: 90, storageMax: 100))

        #expect(currentPlan.quota.status == .full)
        #expect(currentPlan.quota.style == .usedOfTotal)
        #expect(currentPlan.quota.usedBytes == 90)
        #expect(currentPlan.quota.totalBytes == 100)
    }

    @Test func recommendedPlan_isGreenProgressOverPlanStorageAndBestForYouRibbon() {
        let sut = StorageQuotaDialogMapper(severity: .almostFull)
        let account = AccountDetailsEntity.build(storageUsed: 50, storageMax: 100)
        let recommended = sut.recommendedPlan(recommendedEntity(), accountDetails: account)

        #expect(recommended.name == "Essential")
        #expect(recommended.ribbonText == "Best for you")
        #expect(recommended.quotaProgress.status == .good)
        #expect(recommended.quotaProgress.style == .usedOfTotal)
        #expect(recommended.quotaProgress.usedBytes == 50)
        #expect(recommended.quotaProgress.totalBytes > account.storageMax)
    }
}

@Suite("Transfer quota dialog mapper")
struct TransferQuotaDialogMapperTests {
    @Test func header_limitedDownloadFreeAccount_showsRunningLowTitle() throws {
        let sut = TransferQuotaDialogMapper(severity: .limitedDownload)
        let header = try #require(sut.header(accountDetails: .build(proLevel: .free)).transferHeader)

        #expect(header.title == "Your transfer quota is running low")
        #expect(header.learnMore.text == "Learn more.")
    }

    @Test func header_limitedDownloadPaidAccount_showsPercentTitle() throws {
        let sut = TransferQuotaDialogMapper(severity: .limitedDownload)
        let header = try #require(sut.header(accountDetails: .build(transferUsed: 80, transferMax: 100, proLevel: .proI)).transferHeader)

        #expect(header.title == "You've used 80% of your transfer quota")
    }

    @Test func header_exceeded_showsExceededTitle() throws {
        let sut = TransferQuotaDialogMapper(severity: .downloadExceeded)
        let header = try #require(sut.header(accountDetails: .build(proLevel: .proI)).transferHeader)

        #expect(header.title == "Transfer quota exceeded")
    }

    @Test func currentPlan_freeAccountUsesUsedOnlyStyle() {
        let sut = TransferQuotaDialogMapper(severity: .limitedDownload)
        let currentPlan = sut.currentPlan(accountDetails: .build(transferUsed: 4, transferMax: 5, proLevel: .free))

        #expect(currentPlan.quota.style == .usedOnly)
        #expect(currentPlan.quota.status == .almostFull)
    }

    @Test func currentPlan_paidAccountUsesUsedOfTotalStyle() {
        let sut = TransferQuotaDialogMapper(severity: .downloadExceeded)
        let currentPlan = sut.currentPlan(accountDetails: .build(transferUsed: 5, transferMax: 5, proLevel: .proI))

        #expect(currentPlan.quota.style == .usedOfTotal)
        #expect(currentPlan.quota.status == .full)
    }
}
