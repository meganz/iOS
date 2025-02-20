import MEGADomain
import MEGAL10n

extension ChatPresenceConfigEntity {
    var autoAwayFormatString: String {
        let hours = Int(autoAwayTimeout / 3600)
        let minutes = Int((autoAwayTimeout % 3600) / 60)
        var hoursAndMinutesString = ""
        if hours != 0 {
            hoursAndMinutesString = Strings.Localizable.Chat.AutoAway.hour(hours)
            if minutes != 0 {
                hoursAndMinutesString = hoursAndMinutesString + " " + Strings.Localizable.Chat.AutoAway.minute(minutes)
            }
        } else {
            hoursAndMinutesString = Strings.Localizable.Chat.AutoAway.minute(minutes)
        }
        return hoursAndMinutesString
    }
}
