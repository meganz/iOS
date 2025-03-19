@testable import DeviceCenter
import MEGADomain
import Testing

@Suite("Device Icon Provider Tests Suite - Testing icon mapping based on user agent and device type using arguments")
struct DeviceIconProviderTestSuite {
    @Test("Returns default icon when user agent is nil", arguments: [
        (true, "mobile"),
        (false, "pc")
    ])
    func returnsDefaultIconWhenUserAgentIsNil(
        isMobile: Bool,
        expectedIcon: String
    ) {
        let sut = DeviceIconProvider()
        #expect(sut.iconName(for: nil, isMobile: isMobile) == expectedIcon,
                "Expected default icon \(expectedIcon) for isMobile=\(isMobile) when user agent is nil")
    }
    
    @Test("Returns correct icon based on user agent string", arguments: [
       // Android devices
       ("Mozilla/5.0 (Linux; Android 10; Mobile)", true, "android"),
       // iPhone devices
       ("Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)", true, "ios"),
       // Linux desktop
       ("Mozilla/5.0 (X11; Linux x86_64)", false, "pcLinux"),
       // Mac desktop
       ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", false, "pcMac"),
       // Windows desktop
       ("Mozilla/5.0 (Windows NT 10.0; Win64; x64)", false, "pcWindows"),
       // Drive-specific user agent (assuming regex matches "drive")
       ("Mozilla/5.0 (MegaDrive)", false, "drive")
   ])
    func returnsCorrectIconForUserAgent(
        userAgent: String,
        isMobile: Bool,
        expectedIcon: String
    ) {
        let sut = DeviceIconProvider()
        #expect(sut.iconName(for: userAgent, isMobile: isMobile) == expectedIcon,
                "Expected icon \(expectedIcon) for user agent \(userAgent)")
    }
}
