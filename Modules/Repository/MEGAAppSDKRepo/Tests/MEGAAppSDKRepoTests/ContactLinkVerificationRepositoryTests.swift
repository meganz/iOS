import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import Testing

@Suite("ContactLinkVerificationRepositoryTests")
struct ContactLinkVerificationRepositoryTests {
    static let expectedError = MockError.failingError
    
    static func makeSUT(
        requestResult: MockSdkRequestResult
    ) -> (repository: ContactLinkVerificationRepository, mockSdk: MockSdk) {
        let sdk = MockSdk(requestResult: requestResult)
        let repository = ContactLinkVerificationRepository(sdk: sdk)
        return (repository, sdk)
    }
    
    @Suite("ContactLinksOption tests")
    struct ContactLinksOption {
        @Test("contactLinksOption returns correct flag on success")
        func testContactLinksOptionSuccess() async throws {
            let expectedFlag = true
            let successRequest = MockRequest(handle: 1, flag: expectedFlag)
            let (sut, _) = makeSUT(requestResult: .success(successRequest))
            
            let result = try await sut.contactLinksOption()
            #expect(result == expectedFlag)
        }
        
        @Test("contactLinksOption throws error on failure")
        func testContactLinksOptionFailure() async {
            let (sut, _) = makeSUT(requestResult: .failure(expectedError))
            
            await #expect(throws: expectedError, performing: {
                _ = try await sut.contactLinksOption()
            })
        }
    }
    
    @Suite("UpdateContactLinksOption tests")
    struct UpdateContactLinksOption {
        @Test("updateContactLinksOption completes on success")
        func testUpdateContactLinksOptionSuccess() async throws {
            let successRequest = MockRequest(handle: 1, flag: true)
            let (sut, _) = makeSUT(requestResult: .success(successRequest))
            
            try await sut.updateContactLinksOption(enabled: true)
        }
        
        @Test("updateContactLinksOption throws error on failure")
        func testUpdateContactLinksOptionFailure() async {
            let (sut, _) = makeSUT(requestResult: .failure(expectedError))
            
            await #expect(throws: expectedError, performing: {
                try await sut.updateContactLinksOption(enabled: false)
            })
        }
    }
    
    @Suite("ResetContactLink tests")
    struct ResetContactLink {
        @Test("resetContactLink completes on success")
        func testResetContactLinkSuccess() async throws {
            let successRequest = MockRequest(handle: 1, flag: true)
            let (sut, _) = makeSUT(requestResult: .success(successRequest))
            
            try await sut.resetContactLink()
        }
        
        @Test("resetContactLink throws error on failure")
        func testResetContactLinkFailure() async {
            let (sut, _) = makeSUT(requestResult: .failure(expectedError))
            
            await #expect(throws: expectedError, performing: {
                try await sut.resetContactLink()
            })
        }
    }
}
