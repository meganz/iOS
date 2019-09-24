import UIKit

@objc protocol ChatNotificationControlProtocol where Self: UIViewController {
    weak var tableView: UITableView? { get }
    @objc optional func pushNotificationSettingsLoaded()
}

@objc protocol ChatNotificationControlCellProtocol {
    weak var nameLabel: UILabel? { get }
    weak var notificationsSwitch: UISwitch? { get }
    weak var iconImageView: UIImageView? { get }
}

@objc class ChatNotificationControl: NSObject {
    
    // MARK:- DND Options Enumerator
    // The raw value are in seconds.
    private enum DNDTurnOnOption: TimeInterval {
        case forever = 0
        case thirtyMinutes = 1800
        case oneHour = 3600
        case sixHours = 21600
        case twentyFourHours = 86400
        
        var localizedTitle: String {
            switch self {
                case .forever:
                    return "Until I Turn it On Again"
                        .localized(comment: "Used for showing the text in the action sheet for the forever DND option")
                case .thirtyMinutes:
                    return "30 minutes"
                        .localized(comment: "Used for showing the text in the action sheet for the 30 min DND option")
                case .oneHour:
                    return "1 hour"
                        .localized(comment: "Used for showing the text in the action sheet for the 1 hour DND option")
                case .sixHours:
                    return "6 hours"
                        .localized(comment: "Used for showing the text in the action sheet for the 6 hours DND option")
                case .twentyFourHours:
                    return "24 hours"
                        .localized(comment: "Used for showing the text in the action sheet for the 24 hours DND option")
            }
        }
    }
    
    // MARK:- Constants and Variables

    private var pushNotificationSettings: MEGAPushNotificationSettings? {
        didSet {
            if (oldValue == nil && pushNotificationSettings != nil) {
                if let pushNotificationSettingsLoadedMethod = delegate?.pushNotificationSettingsLoaded {
                    pushNotificationSettingsLoadedMethod()
                }
            }
        }
    }
    
    private weak var delegate: ChatNotificationControlProtocol?

    // MARK:- Initializer

    @objc init(delegate: ChatNotificationControlProtocol) {
        self.delegate = delegate
        super.init()
        MEGASdkManager.sharedMEGASdk()?.getPushNotificationSettings(with: self)
    }
}

// MARK:- Interface methods Extension.

extension ChatNotificationControl {
    
    @objc func configure(cell: ChatNotificationControlCellProtocol, chatId: Int64) {
        cell.nameLabel?.text = "Chat Notifications"
            .localized(comment: "This text will appear in the settings of every chat with the on/off switch")
        
        cell.notificationsSwitch?.isEnabled = isNotificationSettingsLoaded()
        cell.notificationsSwitch?.setOn(!isChatDNDEnabled(chatId: chatId), animated: false)
        cell.iconImageView?.image = #imageLiteral(resourceName: "chatNotifications")
    }
    
    @objc func isChatDNDEnabled(chatId: Int64) -> Bool {
        guard let pushNotificationSettings = pushNotificationSettings else {
            return false
        }
        
        return pushNotificationSettings.isChatDndEnabled(forChatId: chatId)
    }
    
    @objc func turnOnDND(chatId: Int64, sender: UIView) {
        let alertMessage = "Mute chat Notifications for".localized(comment: "Used as DND options title bar message")
        let alertController = UIAlertController(title: nil,
                                                message: alertMessage,
                                                preferredStyle: .actionSheet)
        
        let cancelString = "cancel".localized(comment: "Used as cancel text for the action sheet")
        alertController.addAction(UIAlertAction(title: cancelString,
                                                style: .cancel,
                                                handler: { _ in
                                                    self.delegate?.tableView?.reloadData()
        }))
        
        addDefaultAlertAction(alertController: alertController,
                              dndTurnOnOption: .thirtyMinutes, chatId: chatId)
        
        addDefaultAlertAction(alertController: alertController,
                              dndTurnOnOption: .oneHour, chatId: chatId)
        
        addDefaultAlertAction(alertController: alertController,
                              dndTurnOnOption: .sixHours, chatId: chatId)
        
        addDefaultAlertAction(alertController: alertController,
                              dndTurnOnOption: .twentyFourHours, chatId: chatId)
        
        addDefaultAlertAction(alertController: alertController,
                              dndTurnOnOption: .forever, chatId: chatId)
        
        if UIDevice.current.iPad {
            alertController.modalPresentationStyle = .popover
            alertController.popoverPresentationController?.sourceView = sender
            alertController.popoverPresentationController?.sourceRect = sender.bounds
        }
        
        delegate?.present(alertController, animated: true, completion: nil)
    }
    
    @objc func turnOffDND(chatId: Int64) {
        showProgress()
        pushNotificationSettings?.setChatEnabled(true, forChatId: chatId)
        MEGASdkManager.sharedMEGASdk()?.setPushNotificationSettings(self.pushNotificationSettings, delegate: self)
    }
    
    @objc func timeRemainingForDNDDeactivationString(chatId: Int64) -> String? {
        if isChatDNDEnabled(chatId: chatId) == false {
            return nil
        }
        
        let chatDNDTime = chatDND(chatId: chatId)
        
        if chatDNDTime == 0 {
            return "Muted forever"
                .localized(comment: "When the DND is active, This text appears below the DND on/off switch indicating the time left until DND turns off")
        } else {
            let remainingTime = Int(ceil(Double(chatDNDTime) - NSDate().timeIntervalSince1970))
            
            if let timeString = NSString.mnz_string(fromCallDuration: remainingTime) {
                let timeLeftFormatString = "%@ left".localized(comment: "Used for displaying the time until DND is active")
                return String(format: timeLeftFormatString, timeString) ;
            }
           
            return nil
        }
    }
    
    @objc func isNotificationSettingsLoaded() -> Bool {
        return pushNotificationSettings != nil
    }
}

// MARK:- MEGARequestDelegate

extension ChatNotificationControl: MEGARequestDelegate {
    
    func onRequestFinish(_ api: MEGASdk!, request: MEGARequest!, error: MEGAError!) {
        pushNotificationSettings = request.megaPushNotificationSettings
        delegate?.tableView?.reloadData()
        hideProgress()
    }
}

// MARK:- Private methods extension.

extension ChatNotificationControl {
    
    private func showProgress() {
        if SVProgressHUD.isVisible() {
            return
        }
        
        SVProgressHUD.setDefaultMaskType(.clear)
        SVProgressHUD.show()
    }
    
    private func hideProgress() {
        if SVProgressHUD.isVisible() {
            SVProgressHUD.setDefaultMaskType(.none)
            SVProgressHUD.dismiss()
        }
    }

    private func chatDND(chatId: Int64) -> Int64 {
        guard let pushNotificationSettings = pushNotificationSettings else {
            return -1;
        }
        
        return pushNotificationSettings.chatDnd(forChatId: chatId)
    }
    
    private func addDefaultAlertAction(alertController: UIAlertController,
                                       dndTurnOnOption: DNDTurnOnOption,
                                       chatId: Int64) {
        alertController.addDefaultAction(title: dndTurnOnOption.localizedTitle){ _ in
            self.turnOnDND(chatId: chatId, option: dndTurnOnOption)
        }
    }
    
    private func turnOnDND(chatId: Int64, option: DNDTurnOnOption) {
        showProgress()
        
        if option == .forever {
            pushNotificationSettings?.setChatEnabled(false, forChatId: chatId)
        } else {
            let dndTimeInterval = Int64(ceil(NSDate().timeIntervalSince1970 + option.rawValue))
            pushNotificationSettings?.setChatDndForChatId(chatId, untilTimeStamp: dndTimeInterval)
        }
        
        MEGASdkManager.sharedMEGASdk()?.setPushNotificationSettings(pushNotificationSettings, delegate: self)
    }
}

// MARK:- UIAlertController extension.

fileprivate extension UIAlertController {
    func addDefaultAction(title: String, handler: ((UIAlertAction) -> Void)?) {
        let defaultAlertAction = UIAlertAction(title: title, style: .default, handler: handler)
        defaultAlertAction.mnz_setTitleTextColor(UIColor.mnz_black333333())
        addAction(defaultAlertAction)
    }
}

// MARK:- String extension.

fileprivate extension String {
    func localized(comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
}
