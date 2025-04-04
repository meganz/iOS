import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
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
        func getPSAReturnsEntityOnSuccess() async throws {
            let requestNumber: Int64 = 999
            let sut = makeSUT(requestResult: .success(MockRequest(handle: 1, number: requestNumber)))
            
            let psa = try await sut.getPSA()
            #expect(psa.identifier == requestNumber)
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
