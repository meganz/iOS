@testable import MEGA

struct MockGetSMSUseCase: GetSMSUseCaseProtocol {
    var verifiedNumber: String? = nil
    var regionCodesResult: Result<RegionListEntity, GetSMSErrorEntity> = .failure(.generic)
    
    func verifiedPhoneNumber() -> String? {
        verifiedNumber
    }
    
    func getRegionCallingCodes(completion: @escaping (Result<RegionListEntity, GetSMSErrorEntity>) -> Void) {
        completion(regionCodesResult)
    }
}
