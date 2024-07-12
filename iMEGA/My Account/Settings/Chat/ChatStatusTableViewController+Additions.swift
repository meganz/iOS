import Foundation
import MEGADesignToken
import MEGAL10n
import UIKit

extension ChatStatusTableViewController {

    private enum Constants {
        static let maxAutoawayTimeout: Int = 1457 // 87420 seconds
        static let totalMinutesRows: Int = 60
        static let totalHoursRows: Int = 24
    }
    
    @objc func saveAutoAwayTime() {
        autoAwayTimeoutInMinutes = autoAwayTimePicker.selectedRow(inComponent: PickerComponent.hours.rawValue) * 60 + autoAwayTimePicker.selectedRow(inComponent: PickerComponent.minutes.rawValue)
        
        if autoAwayTimeoutInMinutes == 0 {
            autoAwayTimeoutInMinutes = 1
        }
        
        if autoAwayTimeoutInMinutes > Constants.maxAutoawayTimeout {
            autoAwayTimeoutInMinutes = Constants.maxAutoawayTimeout
        }
        
        if autoAwayTimeoutInMinutes == presenceConfig.autoAwayTimeout / 60 {
            self.isSelectingTimeout = false
            self.tableView.reloadData()
            return
        }

        setPresenceAutoAway(true)
    }
    
    @objc func updateAutoAwayTimeTitle() {
        timeoutAutoAwayLabel.text = formatHoursAndMinutes()
    }
    
    @objc func formatHoursAndMinutes() -> String {
        let hours = Int(presenceConfig.autoAwayTimeout / 3600)
        let minutes = Int((presenceConfig.autoAwayTimeout % 3600) / 60)
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
    
    @objc func configurePickerValues() {
        let hours = Int(presenceConfig.autoAwayTimeout / 3600)
        autoAwayTimePicker.selectRow(hours, inComponent: PickerComponent.hours.rawValue, animated: true)
        let minutes = Int((presenceConfig.autoAwayTimeout % 3600) / 60)
        autoAwayTimePicker.selectRow(minutes, inComponent: PickerComponent.minutes.rawValue, animated: true)
    }
    
    // MARK: Appearance
    @objc func defaultBackgroundColor() -> UIColor {
        TokenColors.Background.page
    }
    
    @objc func primaryTextColor() -> UIColor {
        TokenColors.Text.primary
    }
    
    @objc func secondayTextColor() -> UIColor {
        TokenColors.Text.secondary
    }
    
    @objc func disabledTextColor() -> UIColor {
        TokenColors.Text.disabled
    }
    
    @objc func switchTintColor() -> UIColor {
        TokenColors.Support.success
    }
}

extension ChatStatusTableViewController: UIPickerViewDataSource {
    
    enum PickerComponent: Int, CaseIterable {
        case hours
        case hoursLabel
        case minutes
        case minutesLabel
    }
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        PickerComponent.allCases.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case PickerComponent.hoursLabel.rawValue, PickerComponent.minutesLabel.rawValue:
            return 1
        case PickerComponent.hours.rawValue:
            return Constants.totalHoursRows
        case PickerComponent.minutes.rawValue:
            return Constants.totalMinutesRows
        default:
            return 0
        }
    }
}

extension ChatStatusTableViewController: UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        switch component {
        case PickerComponent.hours.rawValue, PickerComponent.minutes.rawValue:
            label.text = "\(row)"
            label.textAlignment = .right
            label.font = .preferredFont(forTextStyle: .title2)
        case PickerComponent.hoursLabel.rawValue:
            let hour = pickerView.selectedRow(inComponent: PickerComponent.hours.rawValue)
            label.text = Strings.Localizable.Chat.AutoAway.Label.hour(hour)
            label.textAlignment = .left
            label.font = .preferredFont(forTextStyle: .body)
        case PickerComponent.minutesLabel.rawValue:
            let minutes = pickerView.selectedRow(inComponent: PickerComponent.minutes.rawValue)
            label.text = Strings.Localizable.Chat.AutoAway.Label.minute(minutes)
            label.textAlignment = .left
            label.font = .preferredFont(forTextStyle: .body)
        default:
            label.text = ""
        }
            
        return label
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let hourComponent = pickerView.selectedRow(inComponent: PickerComponent.hours.rawValue)
        let minuteComponent = pickerView.selectedRow(inComponent: PickerComponent.minutes.rawValue)
        autoAwayTimeSaveButton.isEnabled = !(hourComponent == 0 && minuteComponent == 0)
        
        if component == PickerComponent.hours.rawValue {
            pickerView.reloadComponent(PickerComponent.hoursLabel.rawValue)
        } else if component == PickerComponent.minutes.rawValue {
            pickerView.reloadComponent(PickerComponent.minutesLabel.rawValue)
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        switch component {
        case PickerComponent.hoursLabel.rawValue:
            return pickerView.frame.width * 0.18
        case PickerComponent.hours.rawValue:
            return pickerView.frame.width * 0.32
        case PickerComponent.minutesLabel.rawValue:
            return pickerView.frame.width * 0.35
        case PickerComponent.minutes.rawValue:
            return pickerView.frame.width * 0.15
        default:
            return 0
        }
    }
}
