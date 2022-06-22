import Foundation

enum DNDTurnOnOption: String, CaseIterable {
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
    
    var localizedTitle: String {
        switch self {
        case .thirtyMinutes:
            return Strings.Localizable._30Minutes
        case .oneHour:
            return Strings.Localizable._1Hour
        case .sixHours:
            return Strings.Localizable._6Hours
        case .twentyFourHours:
            return Strings.Localizable._24Hours
        case .morningEightAM:
            return isMorningEightToday ?  Strings.Localizable.untilThisMorning : Strings.Localizable.untilTomorrowMorning
        case .forever:
            return Strings.Localizable.untilITurnItBackOn
        }
    }
    
    static func alertController(delegate: DNDTurnOnAlertControllerAction,
                                isGlobalSetting: Bool,
                                identifier: Int64?) -> UIAlertController {
        let alertMessage = Strings.Localizable.muteChatNotificationsFor

        let alertController = UIAlertController(title: nil,
                                                message: alertMessage,
                                                preferredStyle: .actionSheet)
        
        let cancelString = Strings.Localizable.cancel
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
