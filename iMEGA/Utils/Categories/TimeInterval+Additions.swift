
import Foundation

extension TimeInterval {
    var dndFormattedString: String? {
        guard let date = Calendar.current.date(byAdding: .second, value: Int(ceil(self)), to: Date()) else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let time = dateFormatter.string(from: date)
                
        if Calendar.current.isDateInTomorrow(date) {
            return Strings.Localizable.notificationsWillBeSilencedUntilTomorrow(time)
        } else {
            return Strings.Localizable.notificationsWillBeSilencedUntil(time)
        }
    }
}
