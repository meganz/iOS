
import Foundation

extension Int {
    func timeLeftString() -> String? {
        let (hoursLeft, minutesLeft) = calculateTimeLeft()
        
        if hoursLeft > 0 && minutesLeft > 0 {
            if hoursLeft > 1 && minutesLeft > 1 {
                return String(format: AMLocalizedString("%d hours, %d minutes left", "Chat Notifications DND: Remaining time left to deactivate DND - X hours, X minutes left"), hoursLeft, minutesLeft)
            } else if hoursLeft > 1 && minutesLeft == 1 {
                return String(format: AMLocalizedString("%d hours, 1 minute left", "Chat Notifications DND: Remaining time left to deactivate DND - X hours, 1 minute left"), hoursLeft)
            } else if hoursLeft == 1 && minutesLeft > 1 {
                return String(format: AMLocalizedString("1 hour, %d minutes left", "Chat Notifications DND: Remaining time left to deactivate DND - 1 hour, X minutes left"), minutesLeft)
            } else {
                return AMLocalizedString("1 hour, 1 minute left", "Chat Notifications DND: Remaining time left to deactivate DND - 1 hour, 1 minute left")
            }
        } else if hoursLeft > 0 {
            if (hoursLeft == 1) {
                return AMLocalizedString("1 hour left", "Chat Notifications DND: Remaining time left to deactivate DND - 1 hour left")
            } else {
                let timeLeftFormatString = AMLocalizedString("%d hours left", "Chat Notifications DND: Remaining time left to deactivate DND - more than 1 hour left")
                return String(format: timeLeftFormatString, hoursLeft) ;
            }
        } else if minutesLeft > 0 {
            if (minutesLeft == 1) {
                return AMLocalizedString("1 minute left", "Chat Notifications DND: Remaining time left to deactivate DND - 1 minute left")
            } else {
                let timeLeftFormatString = AMLocalizedString("%d minutes left", "Chat Notifications DND: Remaining time left to deactivate DND - more than 1 minute left")
                return String(format: timeLeftFormatString, minutesLeft) ;
            }
        }
        
        return nil
    }
    
    func calculateTimeLeft() -> (hoursLeft: Int, minutesLeft: Int) {
        let (hoursLeftDouble,  minutesFraction) = modf (Double(self) / 3600.0)
        var hoursLeft = Int(hoursLeftDouble)
        var minutesLeft = Int(round(60 * minutesFraction))
        
        if minutesLeft == 60 {
            hoursLeft += 1
            minutesLeft = 0
        }
        
        return (hoursLeft, minutesLeft)
    }
}
