import Foundation
@testable import MEGA

struct MockSMSRepository: SMSRepositoryProtocol {
    var verifiedNumber: String? = nil
    var smsState: SMSStateEntity = .notAllowed
    var regionCodesResult: Result<[RegionEntity], GetSMSErrorEntity> = .failure(.generic)
    var checkCodeResult: Result<String, CheckSMSErrorEntity> = .failure(.generic)
    var sendToNumberResult: Result<String, CheckSMSErrorEntity> = .failure(.generic)
    
    func verifiedPhoneNumber() -> String? {
        verifiedNumber
    }
    
    func getRegionCallingCodes(completion: @escaping (Result<[RegionEntity], GetSMSErrorEntity>) -> Void) {
        completion(regionCodesResult)
    }
    
    func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        completion(checkCodeResult)
    }
    
    func sendVerification(toPhoneNumber number: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        completion(sendToNumberResult)
    }
    
    func checkState() -> SMSStateEntity {
        smsState
    }
}
