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
    
    static func alertController(delegate: DNDTurnOnAlertControllerAction,
                                identifier: Int64?) -> UIAlertController {
        let alertMessage = AMLocalizedString("Mute chat Notifications for", "Chat Notifications DND: Title bar message for the dnd activate options")
        let alertController = UIAlertController(title: nil,
                                                message: alertMessage,
                                                preferredStyle: .actionSheet)
        
        let cancelString = AMLocalizedString("cancel")
        alertController.addAction(UIAlertAction(title: cancelString,
                                                style: .cancel,
                                                handler: delegate.cancelAction))
        
        alertController.addAction(UIAlertAction(title: thirtyMinutes.localizedTitle, style: .default, handler: delegate.action(for: thirtyMinutes, identifier: identifier)))
        
        alertController.addAction(UIAlertAction(title: oneHour.localizedTitle, style: .default, handler: delegate.action(for: oneHour, identifier: identifier)))
        
        alertController.addAction(UIAlertAction(title: sixHours.localizedTitle, style: .default, handler: delegate.action(for: sixHours, identifier: identifier)))
        
        alertController.addAction(UIAlertAction(title: twentyFourHours.localizedTitle, style: .default, handler: delegate.action(for: twentyFourHours, identifier: identifier)))
        
        alertController.addAction(UIAlertAction(title: forever.localizedTitle, style: .default, handler: delegate.action(for: forever, identifier: identifier)))
        
        return alertController
    }
} 
