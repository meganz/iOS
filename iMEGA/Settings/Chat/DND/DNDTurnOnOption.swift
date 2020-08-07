import Foundation

enum DNDTurnOnOption {
    case thirtyMinutes
    case oneHour
    case sixHours
    case twentyFourHours
    case morningEightAM
    case forever
    
    private var isMorningEightToday: Bool {
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.hour], from: Date())
        if let hour = comp.hour, hour < 8 {
            return true
        }

        return false
    }
    
    private var timeLeftUntilEightAM: TimeInterval? {
        let calendar = Calendar.current
        let now = Date()
        
        if let today = now.startOfDay(on: calendar) {
            var dayComponent = DateComponents()
            dayComponent.day = !isMorningEightToday ? 1 : 0
            dayComponent.hour = 8
            
            if let date = calendar.date(byAdding: dayComponent, to: today) {
                return date.timeIntervalSince(now)
            }
        }
        
        return 0
    }
    
    var timeInterval: TimeInterval? {
        switch self {
        case .thirtyMinutes:
            return 3600
        case .oneHour:
            return 3600
        case .sixHours:
            return 21600
        case .twentyFourHours:
            return 86400
        case .morningEightAM:
            return timeLeftUntilEightAM
        case .forever:
            return 0
        }
    }
    
    private var localizedTitle: String {
        switch self {
        case .thirtyMinutes:
            return AMLocalizedString("30 minutes", "Chat Notifications DND: Option that deactivates DND after 30 minutes")
        case .oneHour:
            return AMLocalizedString("1 hour")
        case .sixHours:
            return AMLocalizedString("6 hours")
        case .twentyFourHours:
            return AMLocalizedString("24 hours")
        case .morningEightAM:
            return isMorningEightToday ?  AMLocalizedString("Until this morning") : AMLocalizedString("Until tomorrow morning")
        case .forever:
            return AMLocalizedString("Until I turn it back on")
        }
    }
    
    static func actionSheetViewController(delegate: DNDTurnOnAlertControllerAction,
                                          isGlobalSetting: Bool,
                                          identifier: Int64?) -> ActionSheetViewController {
        let headerTitle = AMLocalizedString("Mute chat Notifications for", "Chat Notifications DND: Title bar message for the dnd activate options")
        
        var actions = [BaseAction]()
        
        actions.append(ActionSheetAction(title: thirtyMinutes.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: thirtyMinutes, identifier: identifier)))

        actions.append(ActionSheetAction(title: oneHour.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: oneHour, identifier: identifier)))
        
        actions.append(ActionSheetAction(title: sixHours.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: sixHours, identifier: identifier)))
        
        actions.append(ActionSheetAction(title: twentyFourHours.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: twentyFourHours, identifier: identifier)))
        
        if isGlobalSetting {
            actions.append(ActionSheetAction(title: morningEightAM.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: morningEightAM, identifier: identifier)))
        } else {
            actions.append(ActionSheetAction(title: forever.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: forever, identifier: identifier)))
        }
        
        let actionSheetViewController = ActionSheetViewController(actions: actions, headerTitle: headerTitle, dismissCompletion: nil, sender: nil)
        
        return actionSheetViewController
    }
} 
