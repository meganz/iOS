import MEGADomain

public struct MockGetSMSUseCase: GetSMSUseCaseProtocol {
    private let verifiedNumber: String?
    private let regionCodesResult: Result<RegionListEntity, GetSMSErrorEntity>
    
    public init(
        verifiedNumber: String? = nil,
        regionCodesResult: Result<RegionListEntity, GetSMSErrorEntity> = .failure(.generic)
    ) {
        self.verifiedNumber = verifiedNumber
        self.regionCodesResult = regionCodesResult
    }
    
    public func verifiedPhoneNumber() -> String? {
        verifiedNumber
    }
    
    public func getRegionCallingCodes() async throws -> RegionListEntity {
        try regionCodesResult.get()
    }
}
