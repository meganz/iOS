import DeviceCenter
import SwiftUI

public final class MockDeviceIconProvider: DeviceIconProviding {
    private var stubbedIconName: String

    public init(stubbedIconName: String = "") {
        self.stubbedIconName = stubbedIconName
    }

    public func iconName(
        for userAgent: String?,
        isMobile: Bool
    ) -> String {
        stubbedIconName
    }
}
