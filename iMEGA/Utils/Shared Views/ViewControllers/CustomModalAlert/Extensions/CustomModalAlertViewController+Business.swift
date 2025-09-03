import Accounts
import Foundation
import MEGAAssets
import MEGAL10n
import SwiftUI

extension CustomModalAlertViewController {
    
    func configureForBusinessGracePeriod() {
        image = MEGAAssets.UIImage.businessPaymentOverdue
        viewTitle = Strings.Localizable.somethingWentWrong
        detail = Strings.Localizable.ThereHasBeenAProblemWithYourLastPayment.pleaseAccessMEGAUsingADesktopBrowserForMoreInformation
        
        dismissButtonTitle = Strings.Localizable.dismiss
        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
                    return
                }
                if rootViewController.isKind(of: UIHostingController<AdsSlotView<MainTabBarWrapper>>.self) == false {
                    (UIApplication.shared.delegate as? AppDelegate)?.showMainTabBar()
                }
            })
        }
    }
}
