import UIKit

@objc protocol PushNotificationControlProtocol where Self: UIViewController {
    weak var tableView: UITableView? { get }
    @objc optional func pushNotificationSettingsLoaded()
}

protocol DNDTurnOnAlertControllerAction {
    var cancelAction: ((UIAlertAction) -> Void)? { get }
    func action(for dndTurnOnOption: DNDTurnOnOption, identifier: Int64?)-> (((UIAlertAction) -> Void)?)
}

class PushNotificationControl: NSObject {
    // MARK:- Constants and Variables
    
    var pushNotificationSettings: MEGAPushNotificationSettings? {
        didSet {
            if (oldValue == nil && pushNotificationSettings != nil) {
                if let pushNotificationSettingsLoadedMethod = delegate?.pushNotificationSettingsLoaded {
                    pushNotificationSettingsLoadedMethod()
                }
            }
        }
    }
    
    private var pushNotificationSettingsDelegate: MEGAGenericRequestDelegate {
        return MEGAGenericRequestDelegate { [weak self] request, error in
            if error.type == .apiENoent {
                self?.pushNotificationSettings = MEGAPushNotificationSettings()
            } else if error.type == .apiOk {
                self?.pushNotificationSettings = request.megaPushNotificationSettings
            }
            
            self?.delegate?.tableView?.reloadData()
            self?.hideProgress()
        }
    }
    
    weak var delegate: PushNotificationControlProtocol?
    
    // MARK:- Initializer
    
    @objc init(delegate: PushNotificationControlProtocol) {
        self.delegate = delegate
        super.init()
        MEGASdkManager.sharedMEGASdk()?.getPushNotificationSettings(with: pushNotificationSettingsDelegate)
    }
    
    //MARK:- Interface.
    
    @objc func isNotificationSettingsLoaded() -> Bool {
        return pushNotificationSettings != nil
    }
}

// MARK:- Methods used by subclass.

extension PushNotificationControl {
    func string(from timeLeft: Int64) -> String? {
        if timeLeft == 0 {
            return AMLocalizedString("Muted forever", "Chat Notifications DND: DND once activated using forever option, this message will appear below the DND on/off switch")
        } else {
            let remainingTime = Int(ceil(Double(timeLeft) - NSDate().timeIntervalSince1970))
            return remainingTime.timeLeftString()
        }
    }
    
    func show(alertController: UIAlertController, sender: UIView) {
        if UIDevice.current.iPad {
            alertController.modalPresentationStyle = .popover
            alertController.popoverPresentationController?.sourceView = sender
            alertController.popoverPresentationController?.sourceRect = sender.bounds
        }
        
        delegate?.present(alertController, animated: true, completion: nil)
    }
    
    func updatePushNotificationSettings(block: () -> Void) {
        guard let pushNotificationSettings = pushNotificationSettings else {
            return
        }
        
        showProgress()
        block()
        MEGASdkManager.sharedMEGASdk()?.setPushNotificationSettings(pushNotificationSettings,
                                                                    delegate: pushNotificationSettingsDelegate)
    }
    
    func dndTimeInterval(dndTurnOnOption: DNDTurnOnOption) -> Int64 {
        return Int64(ceil(Date().timeIntervalSince1970 + dndTurnOnOption.rawValue))
    }
}

//MARK:- Progress extension

extension PushNotificationControl {
    func showProgress() {
        if SVProgressHUD.isVisible() {
            return
        }
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
    }
    
    func hideProgress() {
        if SVProgressHUD.isVisible() {
            SVProgressHUD.setDefaultMaskType(.none)
            SVProgressHUD.dismiss()
        }
    }
}
