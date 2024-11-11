import Foundation

public protocol GetSMSUseCaseProtocol: Sendable {
    func verifiedPhoneNumber() -> String?
    func getRegionCallingCodes() async throws -> RegionListEntity
}

public struct GetSMSUseCase<T: SMSRepositoryProtocol, U: L10nRepositoryProtocol>: GetSMSUseCaseProtocol {
    private let repo: T
    private let l10n: U
    
    public init(repo: T, l10n: U) {
        self.repo = repo
        self.l10n = l10n
    }
    
    public func verifiedPhoneNumber() -> String? {
        repo.verifiedPhoneNumber()
    }
    
    public func getRegionCallingCodes() async throws -> RegionListEntity {
        let appLocale = Locale(
            identifier: Locale.identifier(
                fromComponents: [NSLocale.Key.languageCode.rawValue: l10n.appLanguage]
            )
        )
        
        let allRegions = try await repo.getRegionCallingCodes().map {
            RegionEntity(
                regionCode: $0.regionCode,
                regionName: appLocale.localizedString(forRegionCode: $0.regionCode),
                callingCodes: $0.callingCodes
            )
        }
        
        let currentRegion = allRegions.first {
            $0.regionCode.caseInsensitiveCompare(l10n.deviceRegion) == .orderedSame
        }
        
        return RegionListEntity(
            currentRegion: currentRegion,
            allRegions: allRegions
        )
    }
}
