import Foundation

class GlobalDNDNotificationControl: PushNotificationControl {
    
    // MARK:- Interface variables and methods.
    
    @objc var timeRemainingToDeactiveDND: String? {
        guard let settings = pushNotificationSettings,
            settings.globalChatsDndEnabled else {
                return nil
        }
        
        let globalDNDTimestamp = settings.globalChatsDNDTimestamp
        return string(from: Int64(globalDNDTimestamp))
    }
    
    @objc var isGlobalDNDEnabled: Bool {
        return pushNotificationSettings?.globalChatsDndEnabled ?? false
    }
    
    @objc var isForeverOptionEnabled: Bool {
        guard let pushNotificationSettings = pushNotificationSettings else {
            return false
        }
        
        return (isGlobalDNDEnabled && (pushNotificationSettings.globalChatsDNDTimestamp == 0))
    }
    
    @objc func turnOnDND(_ sender: UIView) {
        let alertController = DNDTurnOnOption.alertController(delegate: self, isGlobalSetting: true, identifier: nil)
        show(alertController: alertController, sender: sender)
    }
    
    @objc func turnOffChatNotification() {
        updatePushNotificationSettings {
            self.pushNotificationSettings?.globalChatsDndEnabled = true
        }
    }
    
    @objc func turnOffDND() {
        updatePushNotificationSettings {
            self.pushNotificationSettings?.globalChatsDndEnabled = false
        }
    }
    
    @objc func configure(dndSwitch: UISwitch) {
        dndSwitch.isEnabled = isNotificationSettingsLoaded()
        dndSwitch.setOn(isGlobalDNDEnabled, animated: false)
    }
    
    @objc func configure(notificationSwitch: UISwitch) {
        notificationSwitch.isEnabled = isNotificationSettingsLoaded()
        notificationSwitch.setOn(!isForeverOptionEnabled, animated: false)
    }
}

// MARK:- Private method extension

extension GlobalDNDNotificationControl {
    private func turnOnDND(dndTurnOnOption: DNDTurnOnOption) {
        updatePushNotificationSettings {
            if let timeStamp = dndTimeInterval(dndTurnOnOption: dndTurnOnOption) {
                self.pushNotificationSettings?.globalChatsDNDTimestamp = timeStamp
            } else {
                MEGALogDebug("[GlobalDNDNotificationControl] timestamp is nil")
            }
        }
    }
}


// MARK:- DNDTurnOnAlertControllerAction extension

extension GlobalDNDNotificationControl: DNDTurnOnAlertControllerAction {
    var cancelAction: ((UIAlertAction) -> Void)? {
        return { _ in
            self.delegate?.tableView?.reloadData()
        }
    }
    
    func action(for dndTurnOnOption: DNDTurnOnOption, identifier: Int64?) -> (((UIAlertAction) -> Void)?) {
        return { _ in
            self.turnOnDND(dndTurnOnOption: dndTurnOnOption)
        }
    }
}
