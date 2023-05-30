import UIKit
import MEGADomain

@objc protocol ChatNotificationControlCellProtocol {
    weak var nameLabel: UILabel? { get }
    weak var controlSwitch: UISwitch? { get }
    weak var iconImageView: UIImageView? { get }
}

@objc class ChatNotificationControl: PushNotificationControl {
    // MARK: - Interface methods.

    @objc func configure(cell: ChatNotificationControlCellProtocol, chatId: ChatIdEntity) {
        
        cell.nameLabel?.text = Strings.Localizable.chatNotifications
        
        cell.controlSwitch?.isEnabled = isNotificationSettingsLoaded()
        cell.controlSwitch?.setOn(!isChatDNDEnabled(chatId: chatId), animated: false)
        cell.iconImageView?.image = Asset.Images.Chat.chatNotifications.image
    }
    
    @objc func isChatDNDEnabled(chatId: ChatIdEntity) -> Bool {
        guard let pushNotificationSettings = pushNotificationSettings else {
            return false
        }
        
        return pushNotificationSettings.isChatDndEnabled(forChatId: chatId)
    }
    
    @objc func turnOnDND(chatId: ChatIdEntity, sender: UIView) {
        let alertController = DNDTurnOnOption.alertController(delegate: self, isGlobalSetting: false, identifier: chatId)
        show(alertController: alertController, sender: sender)
    }
    
    @objc func turnOffDND(chatId: ChatIdEntity) {
        updatePushNotificationSettings {
            self.pushNotificationSettings?.setChatEnabled(true, forChatId: chatId)
        }
    }
    
    @objc func timeRemainingForDNDDeactivationString(chatId: ChatIdEntity) -> String? {
        if isChatDNDEnabled(chatId: chatId) == false {
            return nil
        }
        
        let chatDNDTime = chatDND(chatId: chatId)
        return string(from: chatDNDTime)
    }
    
    static func dndTurnOnOptions() -> [DNDTurnOnOption] {
        DNDTurnOnOption.options(forGlobalSetting: false)
    }
    
    func turnOnDND(chatId: ChatIdEntity, option: DNDTurnOnOption) {
        updatePushNotificationSettings {
            if let timeStamp = dndTimeInterval(dndTurnOnOption: option) {
                if option == .forever {
                    self.pushNotificationSettings?.setChatEnabled(false, forChatId: chatId)
                } else {
                    self.pushNotificationSettings?.setChatDndForChatId(chatId, untilTimestamp: timeStamp)
                }
            } else {
                MEGALogDebug("[ChatNotificationControl] timestamp is nil")
            }
        }
    }
}

// MARK: - Private methods extension.

extension ChatNotificationControl {

    private func chatDND(chatId: ChatIdEntity) -> Int64 {
        guard let pushNotificationSettings = pushNotificationSettings else {
            return -1
        }
        
        return pushNotificationSettings.timestamp(forChatId: chatId)
    }
}

// MARK: - DNDTurnOnAlertControllerAction extension

extension ChatNotificationControl: DNDTurnOnAlertControllerAction {
  
    var cancelAction: ((UIAlertAction) -> Void)? {
        return { _ in
            self.delegate?.reloadDataIfNeeded?()
        }
    }
    
    func action(for dndTurnOnOption: DNDTurnOnOption, identifier: ChatIdEntity?) -> (((UIAlertAction) -> Void)?) {
        return { _ in
            guard let chatId = identifier else { return }
            self.turnOnDND(chatId: chatId, option: dndTurnOnOption)
        }
    }
}
