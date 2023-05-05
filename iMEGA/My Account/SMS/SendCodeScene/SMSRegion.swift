import Foundation
import MEGADomain

final class SMSRegion {
    let regionCode: RegionCode
    let displayCallingCode: String
    @objc let displayName: String
    
    init(regionCode: RegionCode, displayCallingCode: String, displayName: String) {
        self.regionCode = regionCode
        self.displayCallingCode = displayCallingCode
        self.displayName = displayName
    }
}

extension SMSRegion: Equatable {
    static func == (lhs: SMSRegion, rhs: SMSRegion) -> Bool {
        lhs.displayCallingCode == rhs.displayCallingCode &&
            lhs.displayName == rhs.displayName
    }
}

extension RegionEntity {
    func toSMSRegion() -> SMSRegion? {
        guard let regionName = regionName, let callingCode = callingCodes.first else {
            return nil
        }
        
        let displayCallingCode = "+\(callingCode)"
        return SMSRegion(regionCode: regionCode,
                         displayCallingCode: displayCallingCode,
                         displayName: "\(regionName) (\(displayCallingCode))")
    }
}
