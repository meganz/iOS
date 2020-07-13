import Foundation

enum DNDTurnOnOption: TimeInterval {
    case forever = 0
    case thirtyMinutes = 1800
    case oneHour = 3600
    case sixHours = 21600
    case twentyFourHours = 86400
    
    private var localizedTitle: String {
        switch self {
        case .forever:
            return AMLocalizedString("Until I Turn it On Again", "Chat Notifications DND: Option that does not deactivate DND automatically")
        case .thirtyMinutes:
            return AMLocalizedString("30 minutes", "Chat Notifications DND: Option that deactivates DND after 30 minutes")
        case .oneHour:
            return AMLocalizedString("1 hour")
        case .sixHours:
            return AMLocalizedString("6 hours")
        case .twentyFourHours:
            return AMLocalizedString("24 hours")
        }
    }
    
    static func actionSheetViewController(delegate: DNDTurnOnAlertControllerAction,
                                          identifier: Int64?) -> ActionSheetViewController {
        let headerTitle = AMLocalizedString("Mute chat Notifications for", "Chat Notifications DND: Title bar message for the dnd activate options")
        
        var actions = [BaseAction]()
        
        actions.append(ActionSheetAction(title: thirtyMinutes.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: thirtyMinutes, identifier: identifier)))

        actions.append(ActionSheetAction(title: oneHour.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: oneHour, identifier: identifier)))
        
        actions.append(ActionSheetAction(title: sixHours.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: sixHours, identifier: identifier)))
        
        actions.append(ActionSheetAction(title: twentyFourHours.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: twentyFourHours, identifier: identifier)))
        
        actions.append(ActionSheetAction(title: forever.localizedTitle, detail: nil, image: nil, style: .default, actionHandler: delegate.action(for: forever, identifier: identifier)))
        
        let actionSheetViewController = ActionSheetViewController(actions: actions, headerTitle: headerTitle, dismissCompletion: nil, sender: nil)
        
        return actionSheetViewController
    }
} 
