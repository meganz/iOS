import Foundation
import MEGADomain
import MEGASdk

public struct SMSRepository: SMSRepositoryProtocol {
    public static var newRepo: SMSRepository {
        SMSRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func verifiedPhoneNumber() -> String? {
        sdk.smsVerifiedPhoneNumber()
    }
    
    public func getRegionCallingCodes(completion: @escaping (Result<[RegionEntity], GetSMSErrorEntity>) -> Void) {
        sdk.getCountryCallingCodes(with: RequestDelegate { result in
            switch result {
            case .success(let request):
                completion(.success(request.megaStringListDictionary.map {
                    RegionEntity(regionCode: $0.key, regionName: nil, callingCodes: $0.value.toArray())
                }))
            case .failure:
                completion(.failure(GetSMSErrorEntity.failedToGetCallingCodes))
            }
        })
    }
    
    public func checkVerificationCode(_ code: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        sdk.checkSMSVerificationCode(code, delegate: RequestDelegate { result in
            switch result {
            case .success(let request):
                completion(.success(request.text))
            case .failure(let error):
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
            }
        })
    }

    public func sendVerification(toPhoneNumber: String, completion: @escaping (Result<String, CheckSMSErrorEntity>) -> Void) {
        sdk.sendSMSVerificationCode(toPhoneNumber: toPhoneNumber, delegate: RequestDelegate { result in
            switch result {
            case .success(let request):
                completion(.success(request.text))
            case .failure(let error):
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
            }
        })
    }
    
    public func checkState() -> SMSStateEntity {
        sdk.smsAllowedState().toStateEntity()
    }
}
