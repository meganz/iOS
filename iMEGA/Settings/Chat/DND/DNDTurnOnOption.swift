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
            return 1800
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
            return NSLocalizedString("30 minutes", comment: "Chat Notifications DND: Option that deactivates DND after 30 minutes")
        case .oneHour:
            return NSLocalizedString("1hour", comment: "")
        case .sixHours:
            return NSLocalizedString("6 hours", comment: "")
        case .twentyFourHours:
            return NSLocalizedString("24 hours", comment: "")
        case .morningEightAM:
            return isMorningEightToday ?  NSLocalizedString("Until this morning", comment: "") : NSLocalizedString("Until tomorrow morning", comment: "")
        case .forever:
            return NSLocalizedString("Until I turn it back on", comment: "")
        }
    }
    
    static func alertController(delegate: DNDTurnOnAlertControllerAction,
                                isGlobalSetting: Bool,
                                identifier: Int64?) -> UIAlertController {
        let alertMessage = NSLocalizedString("Mute chat Notifications for", comment: "Chat Notifications DND: Title bar message for the dnd activate options")
        let alertController = UIAlertController(title: nil,
                                                message: alertMessage,
                                                preferredStyle: .actionSheet)
        
        let cancelString = NSLocalizedString("cancel", comment: "")
        alertController.addAction(UIAlertAction(title: cancelString,
                                                style: .cancel,
                                                handler: delegate.cancelAction))

        addAction(for: alertController,
                  delegate: delegate,
                  options: [thirtyMinutes, oneHour, sixHours, twentyFourHours, isGlobalSetting ? morningEightAM : forever],
                  identifier: identifier)
        
        return alertController
    }
    
    private static func addAction(for alertController: UIAlertController,
                                  delegate: DNDTurnOnAlertControllerAction,
                                  options: [DNDTurnOnOption],
                                  identifier: Int64?) {
        options
            .map({ UIAlertAction(title: $0.localizedTitle,
                                 style: .default,
                                 handler: delegate.action(for: $0, identifier: identifier))})
            .forEach(alertController.addAction)
    }
} 
