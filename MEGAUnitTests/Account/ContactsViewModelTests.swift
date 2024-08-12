import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentationMock
import MEGASDKRepoMock
import XCTest

final class ContactsViewModelTests: XCTestCase {
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
    
    func testShowAlertForSensitiveDescendants_hiddenNodesFeatureOff_shouldNotShowLoadingOrAlert() {
        let sut = makeSUT(isHiddenNodesEnabled: false)
        
        let exp = expectation(description: "Should not show loading indicator or alert")
        exp.isInverted = true
        
        let loadingSubscription = sut.$isLoading
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
        let alertSubscription = sut.$alertModel
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
        
        sut.showAlertForSensitiveDescendants([MockNode(handle: 1, isMarkedSensitive: true)])
        
        wait(for: [exp], timeout: 0.2)
        [loadingSubscription, alertSubscription].forEach { $0.cancel() }
    }
    
    func testShowAlertForSensitiveDescendants_shareFolderWithModeNodesNotSensitive_shouldToggleIsLoadingCorrectlyAndNotShowAlert() {
        let sut = makeSUT(
            contactsMode: .shareFoldersWith,
            containsSensitiveContent: [:],
            isHiddenNodesEnabled: true)
        
        let (expectationLoadingStates, loadingSubscription) = expectLoadingShowAndDismiss(on: sut)
        let alertExp = expectation(description: "Should not show alert")
        alertExp.isInverted = true
        let alertSubscription = sut.$alertModel
            .dropFirst()
            .sink { _ in
                alertExp.fulfill()
            }
        
        sut.showAlertForSensitiveDescendants([MockNode(handle: 1, isMarkedSensitive: false)])
        
        wait(for: [expectationLoadingStates, alertExp], timeout: 0.5)
        [loadingSubscription, alertSubscription].forEach { $0.cancel() }
    }
    
    func testShowAlertForSensitiveDescendants_shareFolderWithModeNodesSensitive_shouldToggleIsLoadingCorrectlyShowAlertWithCorrectAction() {
        for isMultipleNodes in [true, false] {
            var sensitiveNodes = [MockNode(handle: 1, isMarkedSensitive: true),
                                  MockNode(handle: 2, isMarkedSensitive: true)]
            if !isMultipleNodes {
                sensitiveNodes = [sensitiveNodes.first].compactMap { $0 }
            }
            let sut = makeSUT(
                contactsMode: .shareFoldersWith,
                containsSensitiveContent: Dictionary(uniqueKeysWithValues: sensitiveNodes.map { ($0.handle, true) }),
                isHiddenNodesEnabled: true)
            
            let (expectationLoadingStates, loadingSubscription) = expectLoadingShowAndDismiss(on: sut)
            let dismissViewExp = expectation(description: "Should dismiss view on cancel action")
            let dismissViewSubscription = sut.dismissViewSubject
                .sink {
                    dismissViewExp.fulfill()
                }
            let alertExp = expectation(description: "Should show alert")
            let expectedAlertMessage = if isMultipleNodes {
                Strings.Localizable.ShareFolder.Sensitive.Alert.Message.multi
            } else {
                Strings.Localizable.ShareFolder.Sensitive.Alert.Message.single
            }
            let alertSubscription = sut.$alertModel
                .dropFirst()
                .sink {
                    XCTAssertEqual($0?.title, Strings.Localizable.ShareFolder.Sensitive.Alert.title)
                    XCTAssertEqual($0?.message, expectedAlertMessage)
                    $0?.actions.first { $0.style == .cancel }?.handler()
                    alertExp.fulfill()
                }
            
            sut.showAlertForSensitiveDescendants(sensitiveNodes)
            
            wait(for: [expectationLoadingStates, alertExp, dismissViewExp], timeout: 1.0)
            [loadingSubscription, alertSubscription, dismissViewSubscription]
                .forEach { $0.cancel() }
        }
    }
    
    private func makeSUT(
        contactsMode: ContactsMode = .default,
        isContactVerificationWarningEnabled: Bool = false,
        isSharedFolderOwnerVerified: Bool = false,
        containsSensitiveContent: [HandleEntity: Bool] = [:],
        isHiddenNodesEnabled: Bool = false
    ) -> ContactsViewModel {
        let sdk = MockSdk(
            isContactVerificationWarningEnabled: isContactVerificationWarningEnabled,
            isSharedFolderOwnerVerified: isSharedFolderOwnerVerified
        )
        return ContactsViewModel(
            sdk: sdk,
            contactsMode: contactsMode,
            shareUseCase: MockShareUseCase(
                containsSensitiveContent: containsSensitiveContent
            ),
            featureFlagProvider: MockFeatureFlagProvider(
                list: [.hiddenNodes: isHiddenNodesEnabled])
        )
    }
    
    private func expectLoadingShowAndDismiss(
        on sut: ContactsViewModel,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (XCTestExpectation, AnyCancellable) {
        var expectedLoadingStates = [true, false]
        let exp = expectation(description: "Should show loading states")
        exp.expectedFulfillmentCount = expectedLoadingStates.count
        let subscription = sut.$isLoading
            .dropFirst()
            .sink {
                let expectedLoadingState = expectedLoadingStates.removeFirst()
                XCTAssertEqual($0, expectedLoadingState, "Unexpected loading state: \(expectedLoadingState)", file: file, line: line)
                exp.fulfill()
            }
        
        return (exp, subscription)
    }
}
