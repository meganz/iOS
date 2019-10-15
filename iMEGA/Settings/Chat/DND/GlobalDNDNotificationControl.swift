import Foundation

class GlobalDNDNotificationControl: PushNotificationControl {
    
    // MARK:- Interface variables and methods.
    
    @objc var timeRemainingToDeactiveDND: String? {
        guard let settings = pushNotificationSettings,
            settings.isGlobalDNDEnabled else {
                return nil
        }
        
        let globalDNDTimestamp = settings.globalDNDTimestamp
        return string(from: Int64(globalDNDTimestamp))
    }
    
    @objc var isGlobalDNDEnabled: Bool {
        return pushNotificationSettings?.isGlobalDNDEnabled ?? false
    }
    
    @objc func turnOnDND(_ sender: UIView) {
        let alertController = DNDTurnOnOption.alertController(delegate: self, identifier: nil)
        show(alertController: alertController, sender: sender)
    }
    
    @objc func turnOffDND() {
        updatePushNotificationSettings {
            self.pushNotificationSettings?.disableGlobalDND()
        }
    }
    
    @objc func configure(dndSwitch: UISwitch) {
        dndSwitch.isEnabled = isNotificationSettingsLoaded()
        dndSwitch.setOn(isGlobalDNDEnabled, animated: false)
    }
}

// MARK:- Private method extension

extension GlobalDNDNotificationControl {
    private func turnOnDND(dndTurnOnOption: DNDTurnOnOption) {
        updatePushNotificationSettings {
            if dndTurnOnOption == .forever {
                self.pushNotificationSettings?.setGlobalEnabled(false)
            } else {
                self.pushNotificationSettings?.globalDNDTimestamp = dndTimeInterval(dndTurnOnOption: dndTurnOnOption)
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
