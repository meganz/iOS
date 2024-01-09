@testable import MEGA
import MEGASDKRepoMock
import XCTest

final class ContactsViewModelTests: XCTestCase {
    private func makeSUT(isContactVerificationWarningEnabled: Bool, isSharedFolderOwnerVerified: Bool) -> ContactsViewModel {
            let sdk = MockSdk(
                isContactVerificationWarningEnabled: isContactVerificationWarningEnabled,
                isSharedFolderOwnerVerified: isSharedFolderOwnerVerified
            )
            return ContactsViewModel(sdk: sdk)
        }
    
    func testShouldShowContactsNotVerifiedBanner_whenSharingFolder_contactVerficationOff_shouldBeHidden() {
        let sut = makeSUT(isContactVerificationWarningEnabled: false, isSharedFolderOwnerVerified: true)

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
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: false)

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
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

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
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

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
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

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
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: false)

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
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .folderSharedWith,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }
    
    func testShouldShowContactsNotVerifiedBanner_whenContactsModeIsDefault_shouldBeHidden() {
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .default,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }
    
    func testShouldShowContactsNotVerifiedBanner_whenChatStartConversation_shouldBeHidden() {
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .chatStartConversation,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }
    
    func testShouldShowContactsNotVerifiedBanner_whenChatAddParticipant_shouldBeHidden() {
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .chatAddParticipant,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }
    
    func testShouldShowContactsNotVerifiedBanner_whenChatAttachParticipant_shouldBeHidden() {
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .chatAttachParticipant,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }
    
    func testShouldShowContactsNotVerifiedBanner_whenChatCreateGroup_shouldBeHidden() {
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .chatCreateGroup,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }
    
    func testShouldShowContactsNotVerifiedBanner_whenChatNamingGroup_shouldBeHidden() {
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .chatNamingGroup,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }
    
    func testShouldShowContactsNotVerifiedBanner_whenInviteParticipants_shouldBeHidden() {
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .inviteParticipants,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }
    
    func testShouldShowContactsNotVerifiedBanner_whenScheduleMeeting_shouldBeHidden() {
        let sut = makeSUT(isContactVerificationWarningEnabled: true, isSharedFolderOwnerVerified: true)

        let visibleUsersArray: NSMutableArray = [MEGAUser(), MEGAUser()]

        XCTAssertFalse(
            sut.shouldShowUnverifiedContactsBanner(
                contactsMode: .scheduleMeeting,
                selectedUsersArray: nil,
                visibleUsersArray: visibleUsersArray
            )
        )
    }
}
