import DeviceCenter
import MEGAAppPresentation
import UIKit

public final class MockBackupListViewRouter: BackupListRouting {
    public init() {}
    
    public func build() -> UIViewController {
        UIViewController()
    }
    
    public func start() {}
    
    public func updateTitle(_ title: String) {}
}
