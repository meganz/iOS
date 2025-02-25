import MEGADomain
import MEGASdk
import MEGASDKRepoMock
import Testing

@Suite("Error entity mapper tests")
struct ErrorEntityMapperTests {
    
    @Test("Test MEGAErrorType to ErrorTypeEntity mapper")
    func testMEGAErrorTypeToErrorTypeEntity() {
        let errorMappings: [(MEGAErrorType, ErrorTypeEntity)] = [
            (.apiOk, .ok),
            (.apiEInternal, .internalError),
            (.apiEArgs, .badArguments),
            (.apiEAgain, .tryAgain),
            (.apiERateLimit, .tooManyRequest),
            (.apiEFailed, .failedPermanently),
            (.apiETooMany, .tooManyRequestForResource),
            (.apiERange, .outOfRange),
            (.apiEExpired, .resourceExpired),
            (.apiENoent, .resourceNotExists),
            (.apiECircular, .circularLink),
            (.apiEAccess, .accessDenied),
            (.apiEExist, .resourceAlreadyExist),
            (.apiEIncomplete, .incompleteRequest),
            (.apiEKey, .cryptographic),
            (.apiESid, .badSessionID),
            (.apiEBlocked, .resourceAdministrativelyBlocked),
            (.apiEOverQuota, .quotaExceeded),
            (.apiETempUnavail, .resourceTemporarilyUnavailable),
            (.apiETooManyConnections, .tooManyConnections),
            (.apiEWrite, .canNotWrite),
            (.apiERead, .canNotRead),
            (.apiEAppKey, .invalidApplicationKey),
            (.apiESSL, .invalidSSLKey),
            (.apiEgoingOverquota, .notEnoughQuota),
            (.apiERolledBack, .rolledBack),
            (.apiEMFARequired, .multiFactorAuthenticationRequired),
            (.apiEMasterOnly, .businessMasterAccountAccessOnly),
            (.apiEBusinessPastDue, .businessAccountExpired),
            (.apiEPaywall, .overDiskQuotaPaywall)
        ]
        
        for (megaErrorType, errorTypeEntity) in errorMappings {
            #expect(megaErrorType.toErrorTypeEntity() == errorTypeEntity)
        }
    }
    
    @Test("Test MEGAError to ErrorEntity mapper")
    func testMEGAErrorToErrorEntity() {
        let megaError = MockError(errorType: .apiEArgs, name: "TestError", value: 1)
        let errorEntity: ErrorEntity = megaError.toErrorEntity()
        
        #expect(errorEntity.type == .badArguments)
        #expect(errorEntity.name == "TestError")
        #expect(errorEntity.value == 1)
    }
}
