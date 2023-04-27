import Foundation
import MEGADomain

public struct MockSMSRepository: SMSRepositoryProtocol {
    public static var newRepo: MockSMSRepository {
        MockSMSRepository()
    }
    
    private let verifiedNumber: String?
    private let smsState: SMSStateEntity
    private let regionCodesResult: Result<[RegionEntity], GetSMSErrorEntity>
    private let checkCodeResult: Result<String, CheckSMSErrorEntity>
    private let sendToNumberResult: Result<String, CheckSMSErrorEntity>
    
    public init(verifiedNumber: String? = nil,
                smsState: SMSStateEntity = .notAllowed,
                regionCodesResult: Result<[RegionEntity], GetSMSErrorEntity> = .failure(.generic),
                checkCodeResult: Result<String, CheckSMSErrorEntity> = .failure(.generic),
                sendToNumberResult: Result<String, CheckSMSErrorEntity> = .failure(.generic)) {
        self.verifiedNumber = verifiedNumber
        self.smsState = smsState
        self.regionCodesResult = regionCodesResult
        self.checkCodeResult = checkCodeResult
        self.sendToNumberResult = sendToNumberResult
    }
    
    public func verifiedPhoneNumber() -> String? {
        verifiedNumber
    }
    
    public func getRegionCallingCodes(completion: @escaping (Result<[RegionEntity], GetSMSErrorEntity>) -> Void) {
        completion(regionCodesResult)
    }
    
    public func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        completion(checkCodeResult)
    }
    
    public func sendVerification(toPhoneNumber: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        completion(sendToNumberResult)
    }
    
    public func checkState() -> SMSStateEntity {
        smsState
    }
}
