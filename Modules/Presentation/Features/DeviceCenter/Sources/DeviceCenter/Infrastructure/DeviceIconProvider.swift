import MEGADomain
import SwiftUI

public protocol DeviceIconProviding {
    func iconName(
        for userAgent: String?,
        isMobile: Bool
    ) -> String
}

public final class DeviceIconProvider: DeviceIconProviding {
    private let iconMapping: [BackupDeviceTypeEntity: String] = [
        .android: "android",
        .iphone: "ios",
        .linux: "pcLinux",
        .mac: "pcMac",
        .win: "pcWindows",
        .drive: "drive",
        .defaultMobile: "mobile",
        .defaultPc: "pc"
    ]
    
    public init() {}
    
    /// Determines the correct icon based on the user agent string and mobile flag.
    ///
    /// - Parameters:
    ///   - userAgent: The user agent string to analyze.
    ///   - isMobile: A Boolean flag indicating if the device is mobile.
    /// - Returns: The corresponding icon as an Image.
    public func iconName(for userAgent: String?, isMobile: Bool) -> String {
        let defaultEntity: BackupDeviceTypeEntity = isMobile ? .defaultMobile : .defaultPc
        let defaultIcon = iconMapping[defaultEntity] ?? "pc"
        guard let userAgent = userAgent else { return defaultIcon }
        
        let matches = iconMapping.compactMap { (entity, iconName) -> (iconName: String, priority: Int)? in
            if userAgent.lowercased().matches(regex: entity.toRegexString()) {
                return (iconName: iconName, priority: entity.priority())
            }
            return nil
        }
        
        return matches.max(by: { $0.priority < $1.priority })?.iconName ?? defaultIcon
    }
}
