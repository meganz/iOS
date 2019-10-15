
import Foundation

extension Int {
    func timeLeftString() -> String? {
        let (hoursLeft, minutesLeft) = calculateTimeLeft()
        
        if hoursLeft > 0 && minutesLeft > 0 {
            if hoursLeft > 1 && minutesLeft > 1 {
                return String(format: "%d hours, %d minutes left".localized(), hoursLeft, minutesLeft)
            } else if hoursLeft > 1 && minutesLeft == 1 {
                return String(format: "%d hours, 1 minute left".localized(), hoursLeft)
            } else if hoursLeft == 1 && minutesLeft > 1 {
                return String(format: "1 hour, %d minutes left".localized(), minutesLeft)
            } else {
                return "1 hour, 1 minute left".localized()
            }
        } else if hoursLeft > 0 {
            if (hoursLeft == 1) {
                return "1 hour left".localized()
            } else {
                let timeLeftFormatString = "%d hours left".localized()
                return String(format: timeLeftFormatString, hoursLeft) ;
            }
        } else if minutesLeft > 0 {
            if (minutesLeft == 1) {
                return "1 minute left".localized()
            } else {
                let timeLeftFormatString = "%d minutes left".localized()
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
