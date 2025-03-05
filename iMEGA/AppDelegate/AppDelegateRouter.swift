import UIKit

@MainActor
protocol AppDelegateRouting {
    func showOverDiskQuota()
}

struct AppDelegateRouter: AppDelegateRouting {
    private let appDelegate: AppDelegate?
    
    init(appDelegate: AppDelegate? = UIApplication.shared.delegate as? AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    func showOverDiskQuota() {
        appDelegate?.presentOverDiskQuota()
    }
}
