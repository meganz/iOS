import Foundation
import MEGAData
import MEGADomain

struct SMSRepository: SMSRepositoryProtocol {
    private let sdk: MEGASdk
    
    init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    func verifiedPhoneNumber() -> String? {
        sdk.smsVerifiedPhoneNumber()
    }
    
    func getRegionCallingCodes(completion: @escaping (Result<[RegionEntity], GetSMSErrorEntity>) -> Void) {
        sdk.getCountryCallingCodes(with: MEGAGenericRequestDelegate { request, error in
            guard error.type == .apiOk else {
                completion(.failure(GetSMSErrorEntity.failedToGetCallingCodes))
                return
            }
            
            completion(.success(request.megaStringListDictionary.map {
                RegionEntity(regionCode: $0.key, regionName: nil, callingCodes: $0.value.toArray())
            }))
        })
    }
    
    func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        sdk.checkSMSVerificationCode(code, delegate: MEGAGenericRequestDelegate { request, error in
            if error.type == .apiOk {
                completion(.success(request.text))
                return
            }

            let smsError: CheckSMSErrorEntity
            switch error.type {
            case .apiEAccess:
                smsError = .reachedDailyLimit
            case .apiEFailed:
                smsError = .codeDoesNotMatch
            case .apiEExpired:
                smsError = .alreadyVerifiedWithAnotherAccount
            default:
                smsError = .generic
            }
            
            completion(.failure(smsError))
        })
    }

    func sendVerification(toPhoneNumber: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        sdk.sendSMSVerificationCode(toPhoneNumber: toPhoneNumber, delegate: MEGAGenericRequestDelegate { request, error in
            if error.type == .apiOk {
                completion(.success(request.text))
                return
            }
            
            let smsError: CheckSMSErrorEntity
            switch error.type {
            case .apiETempUnavail:
                smsError = .reachedDailyLimit
            case .apiEAccess:
                smsError = .alreadyVerifiedWithCurrentAccount
            case .apiEExist:
                smsError = .alreadyVerifiedWithAnotherAccount
            case .apiEArgs:
                smsError = .wrongFormat
            default:
                smsError = .generic
            }
            
            completion(.failure(smsError))
        })
    }
    
    func checkState() -> SMSStateEntity {
        sdk.smsAllowedState().toStateEntity()
    }
}
