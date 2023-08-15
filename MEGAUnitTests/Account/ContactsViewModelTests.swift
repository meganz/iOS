@testable import MEGA
import MEGASDKRepoMock
import XCTest

final class ContactsViewModelTests: XCTestCase {
    func testShouldShowContactsNotVerifiedBanner_whenSharingFolder_contactVerficationOff_shouldBeHidden() {
        let sut = ContactsViewModel(
            sdk: MockSdk(isSharedFolderOwnerVerified: true),
            featureFlagProvider: MockFeatureFlagProvider(list: [.contactVerification: false])
        )

        let selectedUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .shareFoldersWith,
                selectedUsersArray: selectedUsersArray,
                visibleUsersArray: nil
            )
        )
    }

    func testShouldShowContactsNotVerifiedBanner_whenSharingFolder_withOnlyUnverifiedContacts_shouldBeVisible() {
        let sut = ContactsViewModel(
            sdk: MockSdk(isSharedFolderOwnerVerified: false),
            featureFlagProvider: MockFeatureFlagProvider(list: [.contactVerification: true])
        )

        let selectedUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertTrue(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .shareFoldersWith,
                selectedUsersArray: selectedUsersArray,
                visibleUsersArray: nil
            )
        )
    }

    func testShouldShowContactsNotVerifiedBanner_whenSharingFolder_withOnlyVerifiedContacts_shouldBeHidden() {
        let sut = ContactsViewModel(
            sdk: MockSdk(isSharedFolderOwnerVerified: true),
            featureFlagProvider: MockFeatureFlagProvider(list: [.contactVerification: true])
        )

        let selectedUsersArray: NSMutableArray = [MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .shareFoldersWith,
                selectedUsersArray: selectedUsersArray,
                visibleUsersArray: nil
            )
        )
    }

    func testShouldShowContactsNotVerifiedBanner_whenSharingFolder_withOnlyNonContacts_shouldBeVisible() {
        let sut = ContactsViewModel(
            sdk: MockSdk(isSharedFolderOwnerVerified: true),
            featureFlagProvider: MockFeatureFlagProvider(list: [.contactVerification: true])
        )

        let selectedUsersArray: NSMutableArray = ["test@test.com", "test@test.com"]

        XCTAssertTrue(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .shareFoldersWith,
                selectedUsersArray: selectedUsersArray,
                visibleUsersArray: nil
            )
        )
    }

    func testShouldShowContactsNotVerifiedBanner_whenSharingFolder_withUnverifiedContactsAndNonContacts_shouldBeVisible() {
        let sut = ContactsViewModel(
            sdk: MockSdk(isSharedFolderOwnerVerified: true),
            featureFlagProvider: MockFeatureFlagProvider(list: [.contactVerification: true])
        )

        let selectedUsersArray: NSMutableArray = [MEGAUser(), "test@test.com", "test@test.com"]

        XCTAssertTrue(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .shareFoldersWith,
                selectedUsersArray: selectedUsersArray,
                visibleUsersArray: nil
            )
        )
    }

    func testShouldShowContactsNotVerifiedBanner_whenManagingFolder_shouldBeVisible() {
        let sut = ContactsViewModel(
            sdk: MockSdk(isSharedFolderOwnerVerified: false),
            featureFlagProvider: MockFeatureFlagProvider(list: [.contactVerification: true])
        )

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertTrue(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .folderSharedWith,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }

    func testShouldShowContactsNotVerifiedBanner_whenManagingFolder_shouldBeHidden() {
        let sut = ContactsViewModel(
            sdk: MockSdk(isSharedFolderOwnerVerified: true),
            featureFlagProvider: MockFeatureFlagProvider(list: [.contactVerification: true])
        )

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .folderSharedWith,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }
}
