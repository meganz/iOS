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
            return "Until I Turn it On Again".localized()
        case .thirtyMinutes:
            return "30 minutes".localized()
        case .oneHour:
            return "1 hour".localized()
        case .sixHours:
            return "6 hours".localized()
        case .twentyFourHours:
            return "24 hours".localized()
        }
    }
    
    static func alertController(delegate: DNDTurnOnAlertControllerAction,
                                identifier: Int64?) -> UIAlertController {
        let alertMessage = "Mute chat Notifications for".localized()
        let alertController = UIAlertController(title: nil,
                                                message: alertMessage,
                                                preferredStyle: .actionSheet)
        
        let cancelString = "cancel".localized()
        alertController.addAction(UIAlertAction(title: cancelString,
                                                style: .cancel,
                                                handler: delegate.cancelAction))
        
        alertController.addDefaultAction(title: thirtyMinutes.localizedTitle,
                                         handler: delegate.action(for: thirtyMinutes, identifier: identifier))
        
        alertController.addDefaultAction(title: oneHour.localizedTitle,
                                         handler: delegate.action(for: oneHour, identifier: identifier))
        
        alertController.addDefaultAction(title: sixHours.localizedTitle,
                                         handler: delegate.action(for: sixHours, identifier: identifier))
        
        alertController.addDefaultAction(title: twentyFourHours.localizedTitle,
                                         handler: delegate.action(for: twentyFourHours, identifier: identifier))
        
        alertController.addDefaultAction(title: forever.localizedTitle,
                                         handler: delegate.action(for: forever, identifier: identifier))
        
        return alertController
    }
} 
