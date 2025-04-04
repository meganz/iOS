@testable import MEGA
import MEGAAppSDKRepoMock
import XCTest

class SDKErrorTests: XCTestCase {
    
    func testTransformError_apiOK() {
        let mockErrorOk = MockError(errorType: .apiOk, name: "api_ok")
        let sdkErrorOk = transform(error: mockErrorOk)
        XCTAssertTrue(sdkErrorOk.isSuccess)
    }
    
    func testTransformError_apiEInternal() {
        let mockErrorInternal = MockError(errorType: .apiEInternal, name: "internal_error")
        let sdkErrorInternal = transform(error: mockErrorInternal)
        switch sdkErrorInternal {
        case .internalError(let description):
            XCTAssertEqual(description, "internal_error")
        default:
            XCTFail("Expected .internalError, got \(sdkErrorInternal)")
        }
    }
    
    func testTransformError_apiEArgs() {
        let mockErrorArgs = MockError(errorType: .apiEArgs, name: "badArguments")
        let sdkErrorArgs = transform(error: mockErrorArgs)
        switch sdkErrorArgs {
        case .badArguments(let description):
            XCTAssertEqual(description, "badArguments")
        default:
            XCTFail("Expected .badArguments, got \(sdkErrorArgs)")
        }
    }
    
    func testTransformError_apiEAgain() {
        let mockErrorAgain = MockError(errorType: .apiEAgain, name: "tryAgain")
        let sdkErrorAgain = transform(error: mockErrorAgain)
        switch sdkErrorAgain {
        case .tryAgain(let description):
            XCTAssertEqual(description, "tryAgain")
        default:
            XCTFail("Expected .tryAgain, got \(sdkErrorAgain)")
        }
    }
    
    func testTransformError_apiERateLimit() {
        let mockErrorRateLimit = MockError(errorType: .apiERateLimit, name: "tooManyRequest")
        let sdkErrorRateLimit = transform(error: mockErrorRateLimit)
        switch sdkErrorRateLimit {
        case .tooManyRequest(let description):
            XCTAssertEqual(description, "tooManyRequest")
        default:
            XCTFail("Expected .tooManyRequest, got \(sdkErrorRateLimit)")
        }
    }
    
    func testTransformError_apiEFailed() {
        let mockErrorFailed = MockError(errorType: .apiEFailed, name: "failedPermanently")
        let sdkErrorFailed = transform(error: mockErrorFailed)
        switch sdkErrorFailed {
        case .failedPermanently(let description):
            XCTAssertEqual(description, "failedPermanently")
        default:
            XCTFail("Expected .failedPermanently, got \(sdkErrorFailed)")
        }
    }
    
    func testTransformError_apiETooMany() {
        let mockErrorTooMany = MockError(errorType: .apiETooMany, name: "tooManyRequestForResource")
        let sdkErrorTooMany = transform(error: mockErrorTooMany)
        switch sdkErrorTooMany {
        case .tooManyRequestForResource(let description, _, _):
            XCTAssertEqual(description, "tooManyRequestForResource")
        default:
            XCTFail("Expected .tooManyRequestForResource, got \(sdkErrorTooMany)")
        }
    }
    
    func testTransformError_apiERange() {
        let mockErrorRange = MockError(errorType: .apiERange, name: "outOfRange")
        let sdkErrorRange = transform(error: mockErrorRange)
        switch sdkErrorRange {
        case .outOfRange(let description):
            XCTAssertEqual(description, "outOfRange")
        default:
            XCTFail("Expected .outOfRange, got \(sdkErrorRange)")
        }
    }
    
    func testTransformError_apiEExpired() {
        let mockErrorExpired = MockError(errorType: .apiEExpired, name: "resourceExpired")
        let sdkErrorExpired = transform(error: mockErrorExpired)
        switch sdkErrorExpired {
        case .resourceExpired(let description):
            XCTAssertEqual(description, "resourceExpired")
        default:
            XCTFail("Expected .resourceExpired, got \(sdkErrorExpired)")
        }
    }
    
    func testTransformError_apiENoent() {
        let mockErrorNoent = MockError(errorType: .apiENoent, name: "resourceNotExists")
        let sdkErrorNoent = transform(error: mockErrorNoent)
        switch sdkErrorNoent {
        case .resourceNotExists(let description, _, _):
            XCTAssertEqual(description, "resourceNotExists")
        default:
            XCTFail("Expected .resourceNotExists, got \(sdkErrorNoent)")
        }
    }
    
    func testTransformError_apiECircular() {
        let mockErrorCircular = MockError(errorType: .apiECircular, name: "circularLink")
        let sdkErrorCircular = transform(error: mockErrorCircular)
        switch sdkErrorCircular {
        case .circularLink(let description):
            XCTAssertEqual(description, "circularLink")
        default:
            XCTFail("Expected .circularLink, got \(sdkErrorCircular)")
        }
    }
    
    func testTransformError_apiEAccess() {
        let mockErrorAccess = MockError(errorType: .apiEAccess, name: "accessDenied")
        let sdkErrorAccess = transform(error: mockErrorAccess)
        switch sdkErrorAccess {
        case .accessDenied(let description):
            XCTAssertEqual(description, "accessDenied")
        default:
            XCTFail("Expected .accessDenied, got \(sdkErrorAccess)")
        }
    }
    
    func testTransformError_apiEExist() {
        let mockErrorExist = MockError(errorType: .apiEExist, name: "resourceAlreadyExist")
        let sdkErrorExist = transform(error: mockErrorExist)
        switch sdkErrorExist {
        case .resourceAlreadyExist(let description):
            XCTAssertEqual(description, "resourceAlreadyExist")
        default:
            XCTFail("Expected .resourceAlreadyExist, got \(sdkErrorExist)")
        }
    }
    
    func testTransformError_apiEIncomplete() {
        let mockErrorIncomplete = MockError(errorType: .apiEIncomplete, name: "incompleteRequest")
        let sdkErrorIncomplete = transform(error: mockErrorIncomplete)
        switch sdkErrorIncomplete {
        case .incompleteRequest(let description):
            XCTAssertEqual(description, "incompleteRequest")
        default:
            XCTFail("Expected .incompleteRequest, got \(sdkErrorIncomplete)")
        }
    }
    
    func testTransformError_apiEKey() {
        let mockErrorKey = MockError(errorType: .apiEKey, name: "cryptographicError")
        let sdkErrorKey = transform(error: mockErrorKey)
        switch sdkErrorKey {
        case .cryptographicError(let description):
            XCTAssertEqual(description, "cryptographicError")
        default:
            XCTFail("Expected .cryptographicError, got \(sdkErrorKey)")
        }
    }
    
    func testTransformError_apiESid() {
        let mockErrorSid = MockError(errorType: .apiESid, name: "badSessionID")
        let sdkErrorSid = transform(error: mockErrorSid)
        switch sdkErrorSid {
        case .badSessionID(let description):
            XCTAssertEqual(description, "badSessionID")
        default:
            XCTFail("Expected .badSessionID, got \(sdkErrorSid)")
        }
    }
    
    func testTransformError_apiEBlocked() {
        let mockErrorBlocked = MockError(errorType: .apiEBlocked, name: "resourceAdministrativelyBlocked")
        let sdkErrorBlocked = transform(error: mockErrorBlocked)
        switch sdkErrorBlocked {
        case .resourceAdministrativelyBlocked(let description):
            XCTAssertEqual(description, "resourceAdministrativelyBlocked")
        default:
            XCTFail("Expected .resourceAdministrativelyBlocked, got \(sdkErrorBlocked)")
        }
    }
    
    func testTransformError_apiEOverQuota() {
        let mockErrorOverQuota = MockError(errorType: .apiEOverQuota, name: "quoteExceeded", value: 100)
        let sdkErrorOverQuota = transform(error: mockErrorOverQuota)
        switch sdkErrorOverQuota {
        case .quoteExceeded(let description, let value):
            XCTAssertEqual(description, "quoteExceeded")
            XCTAssertEqual(value, 100)
        default:
            XCTFail("Expected .quoteExceeded, got \(sdkErrorOverQuota)")
        }
    }
    
    func testTransformError_apiETempUnavail() {
        let mockErrorTempUnavail = MockError(errorType: .apiETempUnavail, name: "resourceTemporarilyUnavailable")
        let sdkErrorTempUnavail = transform(error: mockErrorTempUnavail)
        switch sdkErrorTempUnavail {
        case .resourceTemporarilyUnavailable(let description):
            XCTAssertEqual(description, "resourceTemporarilyUnavailable")
        default:
            XCTFail("Expected .resourceTemporarilyUnavailable, got \(sdkErrorTempUnavail)")
        }
    }
    
    func testTransformError_apiETooManyConnections() {
        let mockErrorTooManyConnections = MockError(errorType: .apiETooManyConnections, name: "tooManyConnections")
        let sdkErrorTooManyConnections = transform(error: mockErrorTooManyConnections)
        switch sdkErrorTooManyConnections {
        case .tooManyConnections(let description):
            XCTAssertEqual(description, "tooManyConnections")
        default:
            XCTFail("Expected .tooManyConnections, got \(sdkErrorTooManyConnections)")
        }
    }
    
    func testTransformError_apiEWrite() {
        let mockErrorWrite = MockError(errorType: .apiEWrite, name: "canNotWrite")
        let sdkErrorWrite = transform(error: mockErrorWrite)
        switch sdkErrorWrite {
        case .canNotWrite(let description):
            XCTAssertEqual(description, "canNotWrite")
        default:
            XCTFail("Expected .canNotWrite, got \(sdkErrorWrite)")
        }
    }
    
    func testTransformError_apiERead() {
        let mockErrorRead = MockError(errorType: .apiERead, name: "canNotRead")
        let sdkErrorRead = transform(error: mockErrorRead)
        switch sdkErrorRead {
        case .canNotRead(let description):
            XCTAssertEqual(description, "canNotRead")
        default:
            XCTFail("Expected .canNotRead, got \(sdkErrorRead)")
        }
    }
    
    func testTransformError_apiEAppKey() {
        let mockErrorAppKey = MockError(errorType: .apiEAppKey, name: "invalidApplicationKey")
        let sdkErrorAppKey = transform(error: mockErrorAppKey)
        switch sdkErrorAppKey {
        case .invalidApplicationKey(let description):
            XCTAssertEqual(description, "invalidApplicationKey")
        default:
            XCTFail("Expected .invalidApplicationKey, got \(sdkErrorAppKey)")
        }
    }
    
    func testTransformError_apiESSL() {
        let mockErrorSSL = MockError(errorType: .apiESSL, name: "invalidSSLKey")
        let sdkErrorSSL = transform(error: mockErrorSSL)
        switch sdkErrorSSL {
        case .invalidSSLKey(let description):
            XCTAssertEqual(description, "invalidSSLKey")
        default:
            XCTFail("Expected .invalidSSLKey, got \(sdkErrorSSL)")
        }
    }
    
    func testTransformError_apiEgoingOverquota() {
        let mockErrorOverQuota = MockError(errorType: .apiEgoingOverquota, name: "notEnoughQuota")
        let sdkErrorOverQuota = transform(error: mockErrorOverQuota)
        switch sdkErrorOverQuota {
        case .notEnoughQuota(let description):
            XCTAssertEqual(description, "notEnoughQuota")
        default:
            XCTFail("Expected .notEnoughQuota, got \(sdkErrorOverQuota)")
        }
    }
    
    func testTransformError_apiEMFARequired() {
        let mockErrorMFARequired = MockError(errorType: .apiEMFARequired, name: "multiFactorAuthenticationRequired")
        let sdkErrorMFARequired = transform(error: mockErrorMFARequired)
        switch sdkErrorMFARequired {
        case .multiFactorAuthenticationRequired(let description):
            XCTAssertEqual(description, "multiFactorAuthenticationRequired")
        default:
            XCTFail("Expected .multiFactorAuthenticationRequired, got \(sdkErrorMFARequired)")
        }
    }
    
    func testTransformError_apiEMasterOnly() {
        let mockErrorMasterOnly = MockError(errorType: .apiEMasterOnly, name: "businessAccountAccessOnly")
        let sdkErrorMasterOnly = transform(error: mockErrorMasterOnly)
        switch sdkErrorMasterOnly {
        case .businessAccountAccessOnly(let description):
            XCTAssertEqual(description, "businessAccountAccessOnly")
        default:
            XCTFail("Expected .businessAccountAccessOnly, got \(sdkErrorMasterOnly)")
        }
    }
    
    func testTransformError_apiEBusinessPastDue() {
        let mockErrorBusinessPastDue = MockError(errorType: .apiEBusinessPastDue, name: "businessAccountExpired")
        let sdkErrorBusinessPastDue = transform(error: mockErrorBusinessPastDue)
        switch sdkErrorBusinessPastDue {
        case .businessAccountExpired(let description):
            XCTAssertEqual(description, "businessAccountExpired")
        default:
            XCTFail("Expected .businessAccountExpired, got \(sdkErrorBusinessPastDue)")
        }
    }
    
    func testTransformError_apiEPaywall() {
        let mockErrorPaywall = MockError(errorType: .apiEPaywall, name: "overDiskQuotaPaywall")
        let sdkErrorPaywall = transform(error: mockErrorPaywall)
        switch sdkErrorPaywall {
        case .overDiskQuotaPaywall(let description):
            XCTAssertEqual(description, "overDiskQuotaPaywall")
        default:
            XCTFail("Expected .overDiskQuotaPaywall, got \(sdkErrorPaywall)")
        }
    }
}
