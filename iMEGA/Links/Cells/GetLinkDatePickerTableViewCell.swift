import UIKit

class GetLinkDatePickerTableViewCell: UITableViewCell {

    @IBOutlet weak var datePicker: UIDatePicker!
    
    func configureDatePickerCell(date: Date?) {
        datePicker.minimumDate = Date(timeInterval: 24*60*60, since: Date())
        datePicker.date = date ?? Date(timeInterval: 24*60*60, since: Date())
    }

}
