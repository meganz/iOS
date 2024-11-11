import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

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
    
    public func checkState() -> SMSStateEntity {
        sdk.smsAllowedState().toStateEntity()
    }
    
    public func getRegionCallingCodes() async throws -> [RegionEntity] {
        try await withAsyncThrowingValue { completion in
            sdk.getCountryCallingCodes(with: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.megaStringListDictionary?.map {
                        RegionEntity(regionCode: $0.key, regionName: nil, callingCodes: $0.value.toArray())
                    } ?? []))
                case .failure:
                    completion(.failure(GetSMSErrorEntity.failedToGetCallingCodes))
                }
            })
        }
    }
    
    public func checkVerificationCode(_ code: String) async throws -> String {
        try await withAsyncThrowingValue { completion in
            sdk.checkSMSVerificationCode(code, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.text ?? ""))
                case .failure(let error):
                    let smsError: CheckSMSErrorEntity = switch error.type {
                    case .apiEAccess: .reachedDailyLimit
                    case .apiEFailed: .codeDoesNotMatch
                    case .apiEExpired: .alreadyVerifiedWithAnotherAccount
                    default: .generic
                    }
                    completion(.failure(smsError))
                }
            })
        }
    }
    
    public func sendVerification(toPhoneNumber: String) async throws -> String {
        try await withAsyncThrowingValue { completion in
            sdk.sendSMSVerificationCode(toPhoneNumber: toPhoneNumber, delegate: RequestDelegate { result in
                switch result {
                case .success(let request):
                    completion(.success(request.text ?? ""))
                case .failure(let error):
                    let smsError: CheckSMSErrorEntity = switch error.type {
                    case .apiETempUnavail: .reachedDailyLimit
                    case .apiEAccess: .alreadyVerifiedWithCurrentAccount
                    case .apiEExist: .alreadyVerifiedWithAnotherAccount
                    case .apiEArgs: .wrongFormat
                    default: .generic
                    }
                    completion(.failure(smsError))
                }
            })
        }
    }
}
