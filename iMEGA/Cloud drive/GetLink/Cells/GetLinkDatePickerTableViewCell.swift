import MEGADesignToken
import UIKit

class GetLinkDatePickerTableViewCell: UITableViewCell {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    func configureDatePickerCell(date: Date?) {
        backgroundColor = TokenColors.Background.page
        datePicker.backgroundColor = TokenColors.Background.surface1
        
        datePicker.minimumDate = Date(timeInterval: 24*60*60, since: Date())
        datePicker.date = date ?? Date(timeInterval: 24*60*60, since: Date())
    }
    
}
