import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import UIKit

@objc protocol ChatNotificationControlCellProtocol {
    weak var nameLabel: UILabel? { get }
    weak var controlSwitch: UISwitch? { get }
    weak var iconImageView: UIImageView? { get }
}

@objc class ChatNotificationControl: PushNotificationControl {
    // MARK: - Interface methods.

    /// - Parameter isReachable: Whether the change can reach the API. Passed in by the host, which
    ///   already knows its own reachability and reloads when it changes, so this stays the same
    ///   source of truth as the surrounding rows. With the new offline mode off it is ignored and
    ///   only the settings having loaded matters, as before.
    @objc func configure(
        cell: any ChatNotificationControlCellProtocol,
        chatId: ChatIdEntity,
        isMeeting: Bool,
        isReachable: Bool
    ) {
        let isChangeAllowed = !DIContainer.featureFlagProvider.isNewOfflineModeEnabled || isReachable
        
        cell.nameLabel?.text = isMeeting
            ? Strings.Localizable.Meetings.Info.meetingNotifications
            : Strings.Localizable.chatNotifications
        
        // Changing the setting writes it to the API. Offline the request sits in the SDK retry
        // queue, so the progress indicator it shows would never be dismissed, leaving the screen
        // stuck on a spinner, hence the switch is disabled while there is no connection.
        cell.controlSwitch?.isEnabled = isNotificationSettingsLoaded() && isChangeAllowed
        cell.controlSwitch?.setOn(!isChatDNDEnabled(chatId: chatId), animated: false)
        cell.iconImageView?.image = MEGAAssets.UIImage.chatNotifications
    }
    
    @objc func isChatDNDEnabled(chatId: ChatIdEntity) -> Bool {
        guard let pushNotificationSettings = pushNotificationSettings else {
            return false
        }
        
        return pushNotificationSettings.isChatDndEnabled(forChatId: chatId)
    }
    
    @objc func turnOnDND(chatId: ChatIdEntity, isChatTypeMeeting: Bool, sender: UIView) {
        let alertController = DNDTurnOnOption.alertController(delegate: self, isGlobalSetting: false, isChatTypeMeeting: isChatTypeMeeting, identifier: chatId)
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
