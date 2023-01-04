public struct RegionEntity: Equatable {
    let regionCode: String
    public let regionName: String?
    public let callingCodes: [String]
    
    public init(regionCode: String, regionName: String?, callingCodes: [String]) {
        self.regionCode = regionCode
        self.regionName = regionName
        self.callingCodes = callingCodes
    }
}

public struct RegionListEntity {
    public let currentRegion: RegionEntity?
    public let allRegions: [RegionEntity]
    
    public init(currentRegion: RegionEntity?, allRegions: [RegionEntity]) {
        self.currentRegion = currentRegion
        self.allRegions = allRegions
    }
}
