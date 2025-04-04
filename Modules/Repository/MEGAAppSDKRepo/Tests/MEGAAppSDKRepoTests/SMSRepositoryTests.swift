import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import Testing

@Suite("SMSRepository Test Suite - Verifying SMS repository functionalities.")
struct SMSRepositoryTests {
    private static let phoneNumber = "1234567890"
    private static let validVerificationCode = "1234567890"
    private static let successMessage = "Verification sent"
    private static let regionCodeUS = "US"
    private static let regionCodeCA = "CA"
    
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
            let sut = makeSUT(verifiedPhoneNumber: phoneNumber)
            let result = sut.verifiedPhoneNumber()
            
            #expect(result == phoneNumber, "Expected the verified phone number to match")
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
                        regionCodeUS: MockMEGAStringList(size: 1, strings: ["1"]),
                        regionCodeCA: MockMEGAStringList(size: 1, strings: ["1"])
                    ]
                )
            )
            let sut = makeSUT(requestResult: requestResult)
            
            do {
                let regions = try await sut.getRegionCallingCodes()
                #expect(regions.count == 2, "Expected two regions in the result")
                let regionCodes = regions.map(\.regionCode)
                #expect(regionCodes.contains(regionCodeUS), "Expected to have 'US' as a region code in the array")
                #expect(regionCodes.contains(regionCodeCA), "Expected to have 'CA' as a region code in the array")
            } catch {
                Issue.record("Expected success with region entities")
            }
        }

        @Test("Should return error when SDK call fails")
        func getRegionCallingCodesReturnsErrorWhenSDKFails() async {
            let requestResult: MockSdkRequestResult = .failure(MockError(errorType: .apiEFailed))
            let sut = makeSUT(requestResult: requestResult)
            
            do {
                _ = try await sut.getRegionCallingCodes()
                Issue.record("Expected failure with GetSMSErrorEntity.failedToGetCallingCodes")
            } catch let error as GetSMSErrorEntity {
                #expect(error == .failedToGetCallingCodes, "Expected failure with GetSMSErrorEntity.failedToGetCallingCodes")
            } catch {
                Issue.record("Expected a CheckSMSErrorEntity, but found \(error)")
            }
        }
    }

    // MARK: - Tests for `checkVerificationCode`
    @Suite("Check Verification Code Tests")
    struct CheckVerificationCodeTests {
        
        @Test("Should return phone number when verification code is correct")
        func checkVerificationCodeReturnsPhoneNumberWhenCodeIsCorrect() async {
            let requestResult: MockSdkRequestResult = .success(MockRequest(handle: 1, text: validVerificationCode))
            let sut = makeSUT(requestResult: requestResult)
            
            do {
                let phoneNumber = try await sut.checkVerificationCode(validVerificationCode)
                #expect(phoneNumber == validVerificationCode, "Expected the phone number to match the verification code")
            } catch {
                Issue.record("Expected success with a phone number")
            }
        }
        
        @Test("Should return .codeDoesNotMatch error when code is incorrect")
        func checkVerificationCodeReturnsErrorWhenCodeIsIncorrect() async {
            let requestResult: MockSdkRequestResult = .failure(MockError(errorType: .apiEFailed))
            let sut = makeSUT(requestResult: requestResult)
            
            do {
                _ = try await sut.checkVerificationCode("invalidCode")
                Issue.record("Expected failure with CheckSMSErrorEntity.codeDoesNotMatch")
            } catch let error as CheckSMSErrorEntity {
                #expect(error == .codeDoesNotMatch, "Expected failure with CheckSMSErrorEntity.codeDoesNotMatch")
            } catch {
                Issue.record("Expected a CheckSMSErrorEntity, but found \(error)")
            }
        }
    }

    // MARK: - Tests for `sendVerification`
    @Suite("Send Verification Code Tests")
    struct SendVerificationCodeTests {
        
        @Test("Should return success message when verification code is sent")
        func sendVerificationReturnsSuccessMessageWhenCodeSent() async {
            let requestResult: MockSdkRequestResult = .success(MockRequest(handle: 1, text: successMessage))
            let sut = makeSUT(requestResult: requestResult)
            
            do {
                let message = try await sut.sendVerification(toPhoneNumber: phoneNumber)
                #expect(message == successMessage, "Expected a success message indicating verification was sent")
            } catch {
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
