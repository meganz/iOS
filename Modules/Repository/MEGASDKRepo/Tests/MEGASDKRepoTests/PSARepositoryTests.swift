import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import Testing

@Suite("PSARepository Test Suite - Verifying PSA repository functionalities.")
struct PSARepositoryTests {
    private static func makeSUT(
        requestResult: MockSdkRequestResult = .success(MockRequest(handle: 1))
    ) -> PSARepository {
        let mockSdk = MockSdk(requestResult: requestResult)
        return PSARepository(sdk: mockSdk)
    }
    
    @Suite("Get PSA Tests - Async")
    struct GetPSATestsAsync {
        
        @Test("Should return PSA entity when SDK call succeeds")
        func getPSAReturnsEntityOnSuccess() async {
            let sut = makeSUT(requestResult: .success(MockRequest(handle: 1)))
            
            do {
                let psa = try await sut.getPSA()
                #expect(psa != nil, "Expected a PSA entity when the SDK call succeeds")
            } catch {
                Issue.record("Expected success with a PSA entity, but got an error")
            }
        }
        
        @Test(
            "Should throw expected error based on SDK failure type",
            arguments: [
                (MEGAErrorType.apiENoent, PSAErrorEntity.noDataAvailable),
                (MEGAErrorType.apiEFailed, PSAErrorEntity.generic)
            ]
        )
        func getPSAReturnsExpectedError(
            errorType: MEGAErrorType,
            expectedError: PSAErrorEntity
        ) async {
            let sut = makeSUT(requestResult: .failure(MockError(errorType: errorType)))
            
            await #expect(throws: expectedError) {
                _ = try await sut.getPSA()
            }
        }
    }
}
