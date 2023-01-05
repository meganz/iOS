import Foundation
import MEGADomain

final class SMSRegion {
    let displayCallingCode: String
    @objc let displayName: String
    
    init(displayCallingCode: String, displayName: String) {
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
        return SMSRegion(displayCallingCode: displayCallingCode,
                         displayName: "\(regionName) (\(displayCallingCode))")
    }
}
