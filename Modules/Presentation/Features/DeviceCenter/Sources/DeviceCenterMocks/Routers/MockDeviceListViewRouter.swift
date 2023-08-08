import DeviceCenter
import MEGADomain
import MEGAPresentation
import UIKit

public final class MockDeviceListViewRouter: DeviceListRouting {
    public init() {}
    
    public func build() -> UIViewController {
        UIViewController()
    }
    
    public func start() {}
    
    public func showDeviceBackups(_ device: DeviceEntity) {}
}
