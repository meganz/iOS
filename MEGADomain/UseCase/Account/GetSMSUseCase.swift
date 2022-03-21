import Foundation

// MARK: - Use case protocol -
protocol GetSMSUseCaseProtocol {
    func verifiedPhoneNumber() -> String?
    func getRegionCallingCodes(completion: @escaping (Result<RegionListEntity, GetSMSErrorEntity>) -> Void)
}

// MARK: - Use case implementation -
struct GetSMSUseCase<T: SMSRepositoryProtocol, U: L10nRepositoryProtocol>: GetSMSUseCaseProtocol {
    private let repo: T
    private let l10n: U
    
    init(repo: T, l10n: U) {
        self.repo = repo
        self.l10n = l10n
    }
    
    func verifiedPhoneNumber() -> String? {
        repo.verifiedPhoneNumber()
    }
    
    func getRegionCallingCodes(completion: @escaping (Result<RegionListEntity, GetSMSErrorEntity>) -> Void) {
        repo.getRegionCallingCodes { result in
            completion(result.map {
                let appLocale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.languageCode.rawValue: l10n.appLanguage]))
                
                let allRegions = $0.map {
                    RegionEntity(regionCode: $0.regionCode,
                                 regionName: appLocale.localizedString(forRegionCode: $0.regionCode),
                                 callingCodes: $0.callingCodes)
                }
                
                let currentRegion = allRegions.first {
                    $0.regionCode.caseInsensitiveCompare(l10n.deviceRegion) == .orderedSame
                }
                
                return RegionListEntity(currentRegion: currentRegion, allRegions: allRegions)
            })
        }
    }
}
