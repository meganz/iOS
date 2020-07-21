import Foundation

enum DNDTurnOnOption {
    case thirtyMinutes
    case oneHour
    case sixHours
    case twentyFourHours
    case morningEightAM
    
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
            return isMorningEightToday ?  AMLocalizedString("Until this morning, 08:00") : AMLocalizedString("Until tomorrow morning, 08:00")
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

        addAction(for: alertController,
                  delegate: delegate,
                  options: [thirtyMinutes, oneHour, sixHours, twentyFourHours, morningEightAM],
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
