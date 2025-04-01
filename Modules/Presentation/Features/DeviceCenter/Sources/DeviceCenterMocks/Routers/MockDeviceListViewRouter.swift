import DeviceCenter
import MEGAAppPresentation
import MEGADomain
import UIKit

public final class MockDeviceListViewRouter: DeviceListRouting {
    public init() {}
    
    public func build() -> UIViewController {
        UIViewController()
    }
    
    public func start() {}
    
    public func showDeviceBackups(_ device: DeviceEntity, deviceIcon: String, isCurrentDevice: Bool) {}
    public func showCurrentDeviceEmptyState(_ deviceId: String, deviceName: String, deviceIcon: String) {}
}
