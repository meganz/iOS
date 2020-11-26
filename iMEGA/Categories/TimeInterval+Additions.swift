
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
            return String(format: NSLocalizedString("Notifications will be silenced until tomorrow, %@", comment: "Chat Notifications DND: Remaining time left if until tomorrow"), time)
        } else {
            return String(format: NSLocalizedString("Notifications will be silenced until %@", comment: "Chat Notifications DND: Remaining time left if until today"), time)
        }
    }
}
