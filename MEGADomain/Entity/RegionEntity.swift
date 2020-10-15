import Foundation

struct RegionEntity: Equatable {
    let regionCode: String
    let regionName: String?
    let callingCodes: [String]
}

struct RegionListEntity {
    let currentRegion: RegionEntity?
    let allRegions: [RegionEntity]
}
