import MEGADomain
import MEGADomainMock
import MEGASwift
@testable import QuotaWarnings
import Testing

@Suite("Storage quota dialog mapper")
struct StorageQuotaDialogMapperTests {
    private func recommendedEntity() -> RecommendedUpgradePlanEntity {
        RecommendedUpgradePlanEntity(
            productIdentifier: "essential.yearly",
            name: "Essential",
            storage: "200 GB",
            storageLimit: 200,
            transfer: "2 TB",
            transferLimit: 2048,
            mobileOfferLabel: nil,
            price: .yearly(.init(price: 40, currency: "EUR"))
        )
    }

    @Test func header_almostFull_showsPercentAndAlmostFullCopy() {
        let sut = StorageQuotaDialogMapper(severity: .almostFull)
        let header = sut.header(accountDetails: .build(storageUsed: 90, storageMax: 100), canUpgrade: true)

        #expect(header.title == "Your storage is 90% full")
        #expect(header.subtitle.text == "Upgrade your plan before you run out of space")
    }

    @Test func header_fullFromStorageState_showsFullCopy() {
        let sut = StorageQuotaDialogMapper(severity: .full(.storageState))
        let header = sut.header(accountDetails: .build(storageUsed: 100, storageMax: 100), canUpgrade: true)

        #expect(header.title == "Your storage is 100% full")
        #expect(header.subtitle.text == "Upgrade your plan to get more storage and upload more files")
    }

    @Test func header_fullFromUploadAttempt_showsRunOutOfSpaceCopy() {
        let sut = StorageQuotaDialogMapper(severity: .full(.uploadAttempt))
        let header = sut.header(accountDetails: .build(storageUsed: 100, storageMax: 100), canUpgrade: true)

        #expect(header.title == "Your storage is 100% full")
        #expect(header.subtitle.text == "You’ve run out of storage space. Upgrade your plan to continue uploading")
    }

    @Test func header_noUpgrade_showsManageCopyRegardlessOfSeverity() {
        for severity in [StorageQuotaSeverity.almostFull, .full(.storageState), .full(.uploadAttempt)] {
            let sut = StorageQuotaDialogMapper(severity: severity)
            let header = sut.header(accountDetails: .build(storageUsed: 100, storageMax: 100), canUpgrade: false)

            #expect(header.subtitle.text == "Make room in Cloud drive, or manage your plan at mega.io for more storage")
            #expect(header.subtitle.links.count == 1)
        }
    }

    @Test func header_full_overHundredPercent_showsActualPercentUncapped() {
        let sut = StorageQuotaDialogMapper(severity: .full(.storageState))
        let header = sut.header(accountDetails: .build(storageUsed: 120, storageMax: 100), canUpgrade: true)

        #expect(header.title == "Your storage is 120% full")
    }

    @Test func header_upgradeAvailable_hasNoInlineLink() {
        let sut = StorageQuotaDialogMapper(severity: .almostFull)
        let header = sut.header(accountDetails: .build(storageUsed: 90, storageMax: 100), canUpgrade: true)

        #expect(header.subtitle.links.isEmpty)
    }

    @Test func currentPlan_usesStorageUsageAndSeverityStatus() throws {
        let sut = StorageQuotaDialogMapper(severity: .full(.storageState))
        let currentPlan = try #require(sut.currentPlan(accountDetails: .build(storageUsed: 90, storageMax: 100)))

        #expect(currentPlan.quota.status == .full)
        #expect(currentPlan.quota.usedBytes == 90)
        #expect(currentPlan.quota.totalBytes == 100)
    }

    /// Unlike transfer, every storage tier has a published maximum — free included — so the card always shows.
    @Test(arguments: [AccountTypeEntity.free, .proI])
    func currentPlan_isOfferedToEveryTier(proLevel: AccountTypeEntity) {
        let sut = StorageQuotaDialogMapper(severity: .almostFull)

        #expect(sut.currentPlan(accountDetails: .build(proLevel: proLevel)) != nil)
    }

    @Test func recommendedPlan_isGreenProgressOverPlanStorageAndBestForYouRibbon() throws {
        let sut = StorageQuotaDialogMapper(severity: .almostFull)
        let account = AccountDetailsEntity.build(storageUsed: 50, storageMax: 100)
        let recommended = sut.recommendedPlan(recommendedEntity(), accountDetails: account)
        let quotaProgress = try #require(recommended.quotaProgress)

        #expect(recommended.name == "Essential")
        #expect(recommended.ribbonText == "Best for you")
        #expect(quotaProgress.status == .good)
        #expect(quotaProgress.usedBytes == 50)
        #expect(quotaProgress.totalBytes > account.storageMax)
    }

    /// Defensive only — every storage trigger needs a session — but the card must degrade rather than lie.
    @Test func recommendedPlan_withoutAnAccount_plotsNoUsage() {
        let sut = StorageQuotaDialogMapper(severity: .almostFull)

        #expect(sut.recommendedPlan(recommendedEntity(), accountDetails: nil).quotaProgress == nil)
    }
}

@Suite("Transfer quota dialog mapper")
struct TransferQuotaDialogMapperTests {
    private func recommendedEntity() -> RecommendedUpgradePlanEntity {
        RecommendedUpgradePlanEntity(
            productIdentifier: "essential.yearly",
            name: "Essential",
            storage: "200 GB",
            storageLimit: 200,
            transfer: "2 TB",
            transferLimit: 2048,
            mobileOfferLabel: nil,
            price: .yearly(.init(price: 40, currency: "EUR"))
        )
    }

    @Test func header_limitedDownloadFreeAccount_showsRunningLowTitle() {
        let sut = TransferQuotaDialogMapper(severity: .limitedDownload)
        let header = sut.header(accountDetails: .build(proLevel: .free), canUpgrade: true)

        #expect(header.title == "Your transfer quota is running low")
        #expect(header.subtitle.text == "As a result, your download may be interrupted. Upgrade your plan to get more transfer quota. Learn more")
        #expect(header.subtitle.links.count == 1)
    }

    @Test func header_limitedStreaming_showsRunningLowTitleAndStreamingCopy() {
        let sut = TransferQuotaDialogMapper(severity: .limitedStreaming)
        let header = sut.header(accountDetails: .build(proLevel: .free), canUpgrade: true)

        #expect(header.title == "Your transfer quota is running low")
        #expect(header.subtitle.text == "As a result, media playback may be interrupted. Upgrade your plan to get more transfer quota. Learn more")
        #expect(header.subtitle.links.count == 1)
    }

    @Test func header_limitedDownloadPaidAccount_showsPercentTitle() {
        let sut = TransferQuotaDialogMapper(severity: .limitedDownload)
        let header = sut.header(accountDetails: .build(transferUsed: 80, transferMax: 100, proLevel: .proI), canUpgrade: true)

        #expect(header.title == "You’ve used 80% of your transfer quota")
    }

    @Test func header_exceeded_showsExceededTitle() {
        let sut = TransferQuotaDialogMapper(severity: .downloadExceeded)
        let header = sut.header(accountDetails: .build(proLevel: .proI), canUpgrade: true)

        #expect(header.title == "Transfer quota exceeded")
    }

    @Test(arguments: [
        (TransferQuotaSeverity.limitedDownload, "As a result, your download may be interrupted. Manage your plan at mega.io for more transfer quota"),
        (.limitedStreaming, "As a result, media playback may be interrupted. Manage your plan at mega.io for more transfer quota"),
        (.downloadExceeded, "To continue your download, manage your plan at mega.io for more transfer quota"),
        (.streamingExceeded, "To continue media playback, manage your plan at mega.io for more transfer quota")
    ])
    func header_noUpgrade_showsManageCopyWithMegaIoLink(severity: TransferQuotaSeverity, expectedSubtitle: String) {
        let sut = TransferQuotaDialogMapper(severity: severity)
        let header = sut.header(accountDetails: .build(proLevel: .proIII), canUpgrade: false)

        #expect(header.subtitle.text == expectedSubtitle)
        #expect(header.subtitle.links.count == 1)
    }

    // MARK: - Signed out

    @Test(arguments: [
        (TransferQuotaSeverity.limitedDownload, "Your transfer quota is running low"),
        (.limitedStreaming, "Your transfer quota is running low"),
        (.downloadExceeded, "Transfer quota exceeded"),
        (.streamingExceeded, "Transfer quota exceeded")
    ])
    func header_signedOut_reusesTheFreeAccountTitle(severity: TransferQuotaSeverity, expectedTitle: String) {
        let sut = TransferQuotaDialogMapper(severity: severity)

        // No account to quote a percentage from, so a signed-out viewer gets the free-account copy.
        #expect(sut.header(accountDetails: nil, canUpgrade: true).title == expectedTitle)
    }

    @Test func recommendedPlan_signedOut_plotsNoUsage() {
        let sut = TransferQuotaDialogMapper(severity: .downloadExceeded)

        #expect(sut.recommendedPlan(recommendedEntity(), accountDetails: nil).quotaProgress == nil)
    }

    // MARK: - Current plan card

    /// A free account publishes no transfer maximum (`mxfer` is PRO-only), so there is no honest bar to draw:
    /// no current-plan card, and no usage on the recommended card either.
    @Test func currentPlan_freeAccount_isNotOffered() {
        let sut = TransferQuotaDialogMapper(severity: .limitedDownload)

        #expect(sut.currentPlan(accountDetails: .build(transferUsed: 4, transferMax: 5, proLevel: .free)) == nil)
    }

    @Test func recommendedPlan_freeAccount_plotsNoUsage() {
        let sut = TransferQuotaDialogMapper(severity: .limitedDownload)
        let account = AccountDetailsEntity.build(transferUsed: 4, transferMax: 5, proLevel: .free)

        #expect(sut.recommendedPlan(recommendedEntity(), accountDetails: account).quotaProgress == nil)
    }

    @Test func currentPlan_paidAccount_plotsUsageAgainstTheAccountAllowance() throws {
        let sut = TransferQuotaDialogMapper(severity: .downloadExceeded)
        let currentPlan = try #require(
            sut.currentPlan(accountDetails: .build(transferUsed: 5, transferMax: 5, proLevel: .proI))
        )

        #expect(currentPlan.quota.status == .full)
        #expect(currentPlan.quota.usedBytes == 5)
        #expect(currentPlan.quota.totalBytes == 5)
    }

    @Test func recommendedPlan_paidAccount_plotsUsageAgainstThePlanTransfer() throws {
        let sut = TransferQuotaDialogMapper(severity: .limitedDownload)
        let account = AccountDetailsEntity.build(transferUsed: 4, transferMax: 5, proLevel: .proI)
        let quotaProgress = try #require(sut.recommendedPlan(recommendedEntity(), accountDetails: account).quotaProgress)

        #expect(quotaProgress.status == .good)
        #expect(quotaProgress.usedBytes == 4)
        #expect(quotaProgress.totalBytes == 2048.gigabytesToBytes())
    }
}
