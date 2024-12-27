import MEGADomain
import MEGAL10n
@preconcurrency import MEGASdk
import UIKit

/// A protocol to manage PushNotifications based on user preferences
@MainActor
@objc protocol PushNotificationControlProtocol {
    /// Func to show an alert controler to choose the mute notifications time. Used from UISwitchs in UIViewControllers, not needed for UIMenu in context menus.
    @objc optional func presentAlertController(_ alert: UIAlertController)
    
    /// Func to reload data in the view if it is needed, as adding footer info in UITableViewCells. Not needed for UIMenu in context menus.
    @objc optional func reloadDataIfNeeded()
    
    /// Func to notify that notification setings has been loaded, and views can perform actions as show enabled/disabled or reload the view to add remaining mute time.
    @objc optional func pushNotificationSettingsLoaded()
}

@MainActor
protocol DNDTurnOnAlertControllerAction {
    var cancelAction: ((UIAlertAction) -> Void)? { get }
    func action(for dndTurnOnOption: DNDTurnOnOption, identifier: ChatIdEntity?) -> (((UIAlertAction) -> Void)?)
}

@MainActor
class PushNotificationControl: NSObject, MEGARequestDelegate {
    // MARK: - Constants and Variables
    
    var pushNotificationSettings: MEGAPushNotificationSettings? {
        didSet {
            if oldValue == nil && pushNotificationSettings != nil {
                if let pushNotificationSettingsLoadedMethod = delegate?.pushNotificationSettingsLoaded {
                    pushNotificationSettingsLoadedMethod()
                }
            }
        }
    }
    
    weak var delegate: (any PushNotificationControlProtocol)?
    
    // MARK: - Initializer
    
    @objc init(delegate: any PushNotificationControlProtocol) {
        self.delegate = delegate
        super.init()
        MEGASdk.shared.add(self as (any MEGARequestDelegate))
        MEGASdk.shared.getPushNotificationSettings()
    }
    
    deinit {
        MEGASdk.shared.remove(self as (any MEGARequestDelegate))
    }
    
    // MARK: - Interface.
    
    @objc func isNotificationSettingsLoaded() -> Bool {
        return pushNotificationSettings != nil
    }
    
    // MARK: - MEGARequestDelegate
    nonisolated func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        Task { @MainActor in
            handleOnRequestFinish(request: request, error: error)
        }
    }
    
    // MARK: - Privates
    private func handleOnRequestFinish(request: MEGARequest, error: MEGAError) {
        if (request.type == .MEGARequestTypeGetAttrUser || request.type == .MEGARequestTypeSetAttrUser) && request.paramType == MEGAUserAttribute.pushSettings.rawValue {
            if error.type == .apiENoent {
                self.pushNotificationSettings = MEGAPushNotificationSettings()
            } else if error.type == .apiOk {
                self.pushNotificationSettings = request.megaPushNotificationSettings
            }
            
            self.delegate?.reloadDataIfNeeded?()
            self.hideProgress()
        }
    }
}

// MARK: - Methods used by subclass.

extension PushNotificationControl {
    func string(from timeLeft: Int64) -> String? {
        if timeLeft == 0 {
            return Strings.Localizable.notificationsMuted
        } else {
            let remainingTime = ceil(TimeInterval(timeLeft) - Date().timeIntervalSince1970)
            return remainingTime.dndFormattedString
        }
    }
    
    func show(alertController: UIAlertController, sender: Any) {
        if case Optional<Any>.none = sender { return }
        
        if let popover = alertController.popoverPresentationController {
            alertController.modalPresentationStyle = .popover
            if let barButtonSender = sender as? UIBarButtonItem {
                popover.barButtonItem = barButtonSender
            } else if let viewSender = sender as? UIView {
                popover.sourceView = viewSender
                popover.sourceRect = viewSender.bounds
            }
        }
        delegate?.presentAlertController?(alertController)
    }
    
    func updatePushNotificationSettings(block: () -> Void) {
        guard let pushNotificationSettings = pushNotificationSettings else {
            return
        }
        
        showProgress()
        block()
        MEGASdk.shared.setPushNotificationSettings(pushNotificationSettings)
    }
    
    func dndTimeInterval(dndTurnOnOption: DNDTurnOnOption) -> Int64? {
        guard let timeInterval = dndTurnOnOption.timeInterval else {
            return nil
        }
        
        return Int64(ceil(Date().timeIntervalSince1970 + timeInterval))
    }
}

// MARK: - Progress extension

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
