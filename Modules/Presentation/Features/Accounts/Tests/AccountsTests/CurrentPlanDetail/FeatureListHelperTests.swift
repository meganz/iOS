@testable import Accounts
import MEGADomain
import MEGAL10n
import XCTest

final class FeatureListHelperTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func makeSUT(
        storageMax: Int64 = 1000000000,
        transferMax: Int64 = 500000000,
        unavailableImageName: String = "unavailable",
        availableImageName: String = "available"
    ) -> FeatureListHelper {
        let account = AccountDetailsEntity(
            storageMax: storageMax,
            transferMax: transferMax
        )
        let assets = CancelAccountPlanAssets(
            availableImageName: availableImageName,
            unavailableImageName: unavailableImageName
        )
        return FeatureListHelper(account: account, assets: assets)
    }

    func testCreateCurrentFeatures_shouldReturnCorrectFeatureCount() {
        let sut = makeSUT()
        let features = sut.createCurrentFeatures()
        XCTAssertEqual(features.count, 9, "Expected 9 features but got \(features.count)")
    }

    func testCreateCurrentFeatures_shouldHaveCorrectStorageFeature() {
        let sut = makeSUT()
        let features = sut.createCurrentFeatures()
        let storageFeature = features.first { $0.type == .storage }

        XCTAssertNotNil(storageFeature, "Storage feature should not be nil")
        XCTAssertEqual(storageFeature?.title, Strings.Localizable.storage, "Storage feature title mismatch")
        XCTAssertEqual(storageFeature?.freeText, Strings.Localizable.Storage.Limit.capacity(20), "Storage feature free text mismatch")
        XCTAssertEqual(storageFeature?.proText, String.memoryStyleString(fromByteCount: sut.account.storageMax), "Storage feature pro text mismatch")
    }

    func testCreateCurrentFeatures_shouldHaveCorrectTransferFeature() {
        let sut = makeSUT()
        let features = sut.createCurrentFeatures()
        let transferFeature = features.first { $0.type == .transfer }

        XCTAssertNotNil(transferFeature, "Transfer feature should not be nil")
        XCTAssertEqual(transferFeature?.title, Strings.Localizable.transfer, "Transfer feature title mismatch")
        XCTAssertEqual(transferFeature?.freeText, Strings.Localizable.Limited.Feature.message, "Transfer feature free text mismatch")
        XCTAssertEqual(transferFeature?.proText, String.memoryStyleString(fromByteCount: sut.account.transferMax), "Transfer feature pro text mismatch")
    }

    func testCreateCurrentFeatures_shouldHaveCorrectPasswordProtectedLinksFeature() {
        let sut = makeSUT()
        let features = sut.createCurrentFeatures()
        let passwordProtectedLinksFeature = features.first { $0.type == .passwordProtectedLinks }

        XCTAssertNotNil(passwordProtectedLinksFeature, "Password Protected Links feature should not be nil")
        XCTAssertEqual(passwordProtectedLinksFeature?.title, Strings.Localizable.Password.Protected.Links.title, "Password Protected Links feature title mismatch")
        XCTAssertEqual(passwordProtectedLinksFeature?.freeIconName, sut.assets.unavailableImageName, "Password Protected Links feature free icon name mismatch")
        XCTAssertEqual(passwordProtectedLinksFeature?.proIconName, sut.assets.availableImageName, "Password Protected Links feature pro icon name mismatch")
    }

    func testCreateCurrentFeatures_shouldHaveCorrectLinksWithExpiryDateFeature() {
        let sut = makeSUT()
        let features = sut.createCurrentFeatures()
        let linksWithExpiryDateFeature = features.first { $0.type == .linksWithExpiryDate }

        XCTAssertNotNil(linksWithExpiryDateFeature, "Links With Expiry Date feature should not be nil")
        XCTAssertEqual(linksWithExpiryDateFeature?.title, Strings.Localizable.Links.With.Expiry.Dates.title, "Links With Expiry Date feature title mismatch")
        XCTAssertEqual(linksWithExpiryDateFeature?.freeIconName, sut.assets.unavailableImageName, "Links With Expiry Date feature free icon name mismatch")
        XCTAssertEqual(linksWithExpiryDateFeature?.proIconName, sut.assets.availableImageName, "Links With Expiry Date feature pro icon name mismatch")
    }

    func testCreateCurrentFeatures_shouldHaveCorrectTransferSharingFeature() {
        let sut = makeSUT()
        let features = sut.createCurrentFeatures()
        let transferSharingFeature = features.first { $0.type == .transferSharing }

        XCTAssertNotNil(transferSharingFeature, "Transfer Sharing feature should not be nil")
        XCTAssertEqual(transferSharingFeature?.title, Strings.Localizable.Transfer.Sharing.title, "Transfer Sharing feature title mismatch")
        XCTAssertEqual(transferSharingFeature?.freeIconName, sut.assets.unavailableImageName, "Transfer Sharing feature free icon name mismatch")
        XCTAssertEqual(transferSharingFeature?.proIconName, sut.assets.availableImageName, "Transfer Sharing feature pro icon name mismatch")
    }

    func testCreateCurrentFeatures_shouldHaveCorrectRewindFeature() {
        let sut = makeSUT()
        let features = sut.createCurrentFeatures()
        let rewindFeature = features.first { $0.type == .rewind }

        XCTAssertNotNil(rewindFeature, "Rewind feature should not be nil")
        XCTAssertEqual(rewindFeature?.title, Strings.Localizable.Rewind.Feature.title, "Rewind feature title mismatch")
        XCTAssertEqual(rewindFeature?.freeText, Strings.Localizable.Rewind.For.Free.users, "Rewind feature free text mismatch")
        XCTAssertEqual(rewindFeature?.proText, Strings.Localizable.Rewind.For.Pro.users, "Rewind feature pro text mismatch")
    }

    func testCreateCurrentFeatures_shouldHaveCorrectVPNFeature() {
        let sut = makeSUT()
        let features = sut.createCurrentFeatures()
        let vpnFeature = features.first { $0.type == .vpn }

        XCTAssertNotNil(vpnFeature, "VPN feature should not be nil")
        XCTAssertEqual(vpnFeature?.title, Strings.Localizable.Mega.Vpn.title, "VPN feature title mismatch")
        XCTAssertEqual(vpnFeature?.freeIconName, sut.assets.unavailableImageName, "VPN feature free icon name mismatch")
        XCTAssertEqual(vpnFeature?.proIconName, sut.assets.availableImageName, "VPN feature pro icon name mismatch")
    }

    func testCreateCurrentFeatures_shouldHaveCorrectCallsAndMeetingsDurationFeature() {
        let sut = makeSUT()
        let features = sut.createCurrentFeatures()
        let callsAndMeetingsDurationFeature = features.first { $0.type == .callsAndMeetingsDuration }

        XCTAssertNotNil(callsAndMeetingsDurationFeature, "Calls and Meetings Duration feature should not be nil")
        XCTAssertEqual(callsAndMeetingsDurationFeature?.title, Strings.Localizable.Call.And.Meeting.Duration.title, "Calls and Meetings Duration feature title mismatch")
        XCTAssertEqual(callsAndMeetingsDurationFeature?.freeText, Strings.Localizable.Call.And.Meeting.Duration.For.Free.users, "Calls and Meetings Duration feature free text mismatch")
        XCTAssertEqual(callsAndMeetingsDurationFeature?.proText, Strings.Localizable.Call.And.Meeting.Duration.For.Pro.users, "Calls and Meetings Duration feature pro text mismatch")
    }

    func testCreateCurrentFeatures_shouldHaveCorrectCallsAndMeetingsParticipantsFeature() {
        let sut = makeSUT()
        let features = sut.createCurrentFeatures()
        let callsAndMeetingsParticipantsFeature = features.first { $0.type == .callsAndMeetingsParticipants }

        XCTAssertNotNil(callsAndMeetingsParticipantsFeature, "Calls and Meetings Participants feature should not be nil")
        XCTAssertEqual(callsAndMeetingsParticipantsFeature?.title, Strings.Localizable.Call.And.Meeting.Participants.title, "Calls and Meetings Participants feature title mismatch")
        XCTAssertEqual(callsAndMeetingsParticipantsFeature?.freeText, Strings.Localizable.Call.And.Meeting.Participants.For.Free.users, "Calls and Meetings Participants feature free text mismatch")
        XCTAssertEqual(callsAndMeetingsParticipantsFeature?.proText, Strings.Localizable.Unlimited.Feature.message, "Calls and Meetings Participants feature pro text mismatch")
    }
}
