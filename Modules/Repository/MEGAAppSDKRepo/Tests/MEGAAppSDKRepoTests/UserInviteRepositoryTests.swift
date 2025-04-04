import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class UserInviteRepositoryTests: XCTestCase {

    func testSendInvite_whenSuccess_shouldNotThrow() async {
        let sut = makeSUT(requestResult: .success(MockRequest(handle: 1)))
    
        await XCTAsyncAssertNoThrow(try await sut.sendInvite(forEmail: "test@mega.nz"))
    }
    
    func testSendInvite_whenFailedWithApiEArgs_ownEmailEntered_shouldThrowError() async {
        let ownEmail = "test@mega.nz"
        let sut = makeSUT(
            requestResult: .failure(MockError(errorType: .apiEArgs)),
            myEmail: ownEmail
        )
        
        await XCTAsyncAssertThrowsError(try await sut.sendInvite(forEmail: ownEmail)) { errorThrown in
            XCTAssertEqual(errorThrown as? InviteErrorEntity, .ownEmailEntered)
        }
    }
    
    func testSendInvite_whenFailedWithApiEExist_alreadyAContact_shouldThrowError() async {
        let contactEmail = "test@mega.nz"
        let sut = makeSUT(
            requestResult: .failure(MockError(errorType: .apiEExist)),
            contactUser: MockUser(handle: 1, visibility: .visible, email: contactEmail)
        )
        
        await XCTAsyncAssertThrowsError(try await sut.sendInvite(forEmail: contactEmail)) { errorThrown in
            XCTAssertEqual(errorThrown as? InviteErrorEntity, .alreadyAContact)
        }
    }
    
    func testSendInvite_whenFailedWithApiEExist_isInOutgoingContactRequest_shouldThrowError() async {
        let contactRequest = MockContactRequest(targetEmail: "test@mega.nz")
        let sut = makeSUT(
            requestResult: .failure(MockError(errorType: .apiEExist)),
            contactUser: nil,
            outgoingContactRequests: MockContactRequestList(contactRequests: [contactRequest])
        )
        
        await XCTAsyncAssertThrowsError(try await sut.sendInvite(forEmail: contactRequest.targetEmail)) { errorThrown in
            XCTAssertEqual(errorThrown as? InviteErrorEntity, .isInOutgoingContactRequest)
        }
    }
    
    func testSendInvite_whenFailedWithApiEExist_isNotInOutgoingContactRequest_shouldThrowGenericError() async {
        let expectedErrorName = "Test generic error name"
        let sut = makeSUT(
            requestResult: .failure(MockError(errorType: .apiEExist, name: expectedErrorName)),
            contactUser: nil,
            outgoingContactRequests: MockContactRequestList(contactRequests: [])
        )
        
        await XCTAsyncAssertThrowsError(try await sut.sendInvite(forEmail: "test@mega.nz")) { errorThrown in
            XCTAssertEqual(errorThrown as? InviteErrorEntity, .generic(expectedErrorName))
        }
    }
    
    func testSendInvite_whenFailed_notApiEArgsOrApiEExist_shouldThrowGenericError() async {
        let expectedErrorName = "Test generic error name"
        let randomError = MockError(
            errorType: .anyFailingErrorType(
                excluding: [.apiEArgs, .apiEExist]
            ),
            name: expectedErrorName
        )
        let sut = makeSUT(requestResult: .failure(randomError))
        
        await XCTAsyncAssertThrowsError(try await sut.sendInvite(forEmail: "test@mega.nz")) { errorThrown in
            XCTAssertEqual(errorThrown as? InviteErrorEntity, .generic(expectedErrorName))
        }
    }

    // MARK: - Helper
    
    private func makeSUT(
        requestResult: MockSdkRequestResult = .failure(MockError()),
        myEmail: String? = nil,
        contactUser: MockUser? = nil,
        outgoingContactRequests: MockContactRequestList = MockContactRequestList()
    ) -> UserInviteRepository {
        UserInviteRepository(
            sdk: MockSdk(
                myEmail: myEmail,
                sharedFolderOwner: contactUser,
                requestResult: requestResult,
                outgoingContactRequests: outgoingContactRequests
            )
        )
    }
}
