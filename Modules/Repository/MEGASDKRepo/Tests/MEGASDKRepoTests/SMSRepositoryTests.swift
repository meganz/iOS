import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import Testing

@Suite("SMSRepository Test Suite - Verifying SMS repository functionalities.")
struct SMSRepositoryTests {
    
    // MARK: - Helper Functions
    private static func makeSUT(
        verifiedPhoneNumber: String? = nil,
        requestResult: MockSdkRequestResult = .failure(MockError()),
        smsState: SMSStateEntity = .notAllowed
    ) -> SMSRepository {
        let mockSdk = MockSdk(
            smsState: smsState.toSMSState(),
            requestResult: requestResult,
            verifiedPhoneNumber: verifiedPhoneNumber
        )
        return SMSRepository(sdk: mockSdk)
    }

    // MARK: - Tests for `verifiedPhoneNumber`
    @Suite("Verified Phone Number Tests")
    struct VerifiedPhoneNumberTests {
        
        @Test("Should return the verified phone number when available")
        func verifiedPhoneNumberReturnsPhoneNumberWhenAvailable() {
            let sut = makeSUT(verifiedPhoneNumber: "1234567890")
            let result = sut.verifiedPhoneNumber()
            
            #expect(result == "1234567890", "Expected the verified phone number to match")
        }

        @Test("Should return nil when no verified phone number is available")
        func verifiedPhoneNumberReturnsNilWhenNotAvailable() {
            let sut = makeSUT(verifiedPhoneNumber: nil)
            let result = sut.verifiedPhoneNumber()
            
            #expect(result == nil, "Expected the result to be nil when no phone number is verified")
        }
    }

    // MARK: - Tests for `getRegionCallingCodes`
    @Suite("Get Region Calling Codes Tests")
    struct GetRegionCallingCodesTests {
        
        @Test("Should return region entities when SDK call succeeds")
        func getRegionCallingCodesReturnsRegionsOnSuccess() async {
            let requestResult: MockSdkRequestResult = .success(
                MockRequest(
                    handle: 1,
                    stringListDictionary: [
                        "US": MockMEGAStringList(size: 1, strings: ["1"]),
                        "CA": MockMEGAStringList(size: 1, strings: ["1"])
                    ]
                )
            )
            let sut = makeSUT(requestResult: requestResult)
            
            let result = await withCheckedContinuation { continuation in
                sut.getRegionCallingCodes { result in
                    continuation.resume(returning: result)
                }
            }
            
            switch result {
            case .success(let regions):
                #expect(regions.count == 2, "Expected two regions in the result")
                let regionCodes = regions.map(\.regionCode)
                #expect(regionCodes.contains("US"), "Expected to have 'US' as a region code in the array")
                #expect(regionCodes.contains("CA"), "Expected to have 'CA' as a region code in the array")
            default:
                Issue.record("Expected success with region entities")
            }
        }

        @Test("Should return error when SDK call fails")
        func getRegionCallingCodesReturnsErrorWhenSDKFails() async {
            let requestResult: MockSdkRequestResult = .failure(MockError(errorType: .apiEFailed))
            let sut = makeSUT(requestResult: requestResult)
            
            let result = await withCheckedContinuation { continuation in
                sut.getRegionCallingCodes { result in
                    continuation.resume(returning: result)
                }
            }
            
            switch result {
            case .failure(let error):
                #expect(error == .failedToGetCallingCodes, "Expected failure with GetSMSErrorEntity.failedToGetCallingCodes")
            default:
                Issue.record("Expected failure with GetSMSErrorEntity.failedToGetCallingCodes")
            }
        }
    }

    // MARK: - Tests for `checkVerificationCode`
    @Suite("Check Verification Code Tests")
    struct CheckVerificationCodeTests {
        
        @Test("Should return phone number when verification code is correct")
        func checkVerificationCodeReturnsPhoneNumberWhenCodeIsCorrect() async {
            let validCode = "1234567890"
            let requestResult: MockSdkRequestResult = .success(MockRequest(handle: 1, text: validCode))
            let sut = makeSUT(requestResult: requestResult)
            
            let result = await withCheckedContinuation { continuation in
                sut.checkVerificationCode(validCode) { result in
                    continuation.resume(returning: result)
                }
            }
            
            switch result {
            case .success(let phoneNumber):
                #expect(phoneNumber == validCode, "Expected the phone number to match the verification code")
            default:
                Issue.record("Expected success with a phone number")
            }
        }
        
        @Test("Should return .codeDoesNotMatch error when code is incorrect")
        func checkVerificationCodeReturnsErrorWhenCodeIsIncorrect() async {
            let requestResult: MockSdkRequestResult = .failure(MockError(errorType: .apiEFailed))
            let sut = makeSUT(requestResult: requestResult)
            
            let result = await withCheckedContinuation { continuation in
                sut.checkVerificationCode("invalidCode") { result in
                    continuation.resume(returning: result)
                }
            }
            
            switch result {
            case .failure(let error):
                #expect(error == .codeDoesNotMatch, "Expected failure with CheckSMSErrorEntity.codeDoesNotMatch")
            default:
                Issue.record("Expected failure with CheckSMSErrorEntity.codeDoesNotMatch")
            }
        }
    }

    // MARK: - Tests for `sendVerification`
    @Suite("Send Verification Code Tests")
    struct SendVerificationCodeTests {
        
        @Test("Should return success message when verification code is sent")
        func sendVerificationReturnsSuccessMessageWhenCodeSent() async {
            let requestResult: MockSdkRequestResult = .success(MockRequest(handle: 1, text: "Verification sent"))
            let sut = makeSUT(requestResult: requestResult)
            
            let result = await withCheckedContinuation { continuation in
                sut.sendVerification(toPhoneNumber: "1234567890") { result in
                    continuation.resume(returning: result)
                }
            }
            
            switch result {
            case .success(let message):
                #expect(message == "Verification sent", "Expected a success message indicating verification was sent")
            default:
                Issue.record("Expected success with a message")
            }
        }
    }

    // MARK: - Tests for `checkState`
    @Suite("Check SMS State Tests")
    struct CheckSMSStateTests {
        
        @Test(
            "Should return the correct SMS state",
            arguments: SMSStateEntity.allCases
        )
        func checkStateReturnsCorrectSMSState(smsState: SMSStateEntity) {
            let sut = makeSUT(smsState: smsState)
            let result = sut.checkState()
            
            #expect(result == smsState, "Expected SMS state to be \(smsState)")
        }
    }
}
