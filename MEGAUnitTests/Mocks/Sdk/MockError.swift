import Foundation
@testable import MEGA
import MEGADomain

final class MockError: MEGAError {
    var megaErrorType: MEGAErrorType
    
    init(errorType: MEGAErrorType = .apiOk) {
        megaErrorType = errorType
    }

    override var type: MEGAErrorType {
        megaErrorType
    }
}
