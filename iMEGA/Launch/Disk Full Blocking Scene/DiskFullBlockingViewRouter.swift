import Foundation
import UIKit

final class DiskFullBlockingViewRouter: NSObject, DiskFullBlockingViewRouting {
    private weak var window: UIWindow?
    
    @objc init(window: UIWindow) {
        self.window = window
    }
    
    func build() -> UIViewController {
         DiskFullBlockingViewController(viewModel: DiskFullBlockingViewModel(router: self, deviceModel: UIDevice.current.localizedModel))
    }
    
    @objc func start() {
        window?.rootViewController = build()
        window?.makeKeyAndVisible()
    }
    
    func manageDiskSpace() {
        MEGASdkManager.deleteSharedSdks()
        exit(0)
    }
}
