import Foundation
import MEGAAppPresentation
import MEGAL10n

struct UnitsComponentValues {
    let hours = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24"]
    let days = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"]
    let weeks = ["1", "2", "3", "4"]
    let months = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]
    let year = ["1"]
}

enum MeasurementsComponent: Int {
    case singular = 1
    case plural = 2
    
    func values() -> [String] {
        return [Strings.Localizable.Chat.ManageHistory.Clearing.Custom.Option.hour(self.rawValue),
                 Strings.Localizable.Chat.ManageHistory.Clearing.Custom.Option.day(self.rawValue),
                 Strings.Localizable.Chat.ManageHistory.Clearing.Custom.Option.week(self.rawValue),
                 Strings.Localizable.Chat.ManageHistory.Clearing.Custom.Option.month(self.rawValue),
                 Strings.Localizable.Chat.ManageHistory.Clearing.Custom.Option.year(MeasurementsComponent.singular.rawValue)]
    }
}

enum AutomaticChanges: Int {
    case twelveMonthsToOneYear = 11
    case twentyFourHoursToOneDay = 23
    case thirtyDaysToOneMonth = 29
}

enum HistoryRetentionPickerAction: ActionType {
    case configPicker(UInt)
}

final class HistoryRetentionPickerViewModel: NSObject, ViewModelType {
    enum Command: CommandType {
        case updateHistoryRetentionLabel(String)
        case selectUnitPickerComponent(Int)
        case selectMeasurementPickerComponent(Int)
        case updateUnitPickerComponent
        case updateMeasurementPickerComponent
    }
    
    var unitsValuesArray: [String] = UnitsComponentValues().hours // Default to values for hours, default measurament component
    var measuramentsValuesArray: [String] = MeasurementsComponent.singular.values() // Default to singular, when the picker is shown the default position is '1 hour'
    
    var invokeCommand: ((Command) -> Void)?
        
    func dispatch(_ action: HistoryRetentionPickerAction) {
        switch action {
        case .configPicker(let historyRetentionValue):
            let pickerValue = historyRetentionToPickerValue(historyRetentionValue)
            unitsArrayWhenMeasurementChanges(pickerValue.measurement)
            measuramentsValuesArray = pickerValue.unit >= 1 ? MeasurementsComponent.plural.values() : MeasurementsComponent.singular.values()
            
            self.invokeCommand?(Command.updateUnitPickerComponent)
            self.invokeCommand?(Command.updateMeasurementPickerComponent)
            
            self.invokeCommand?(Command.selectUnitPickerComponent(pickerValue.unit))
            self.invokeCommand?(Command.selectMeasurementPickerComponent(pickerValue.measurement))
        }
    }
    
    // MARK: - Private
    
    private func historyRetentionPickerValueToUInt(_ unitsRow: Int, _ measurementsRow: Int) -> UInt {
        let hoursDaysWeeksMonthsOrYearValue: UInt = UInt(unitsRow + 1)
        let measuramentsComponentValue: [UInt] = [UInt(secondsInAHour), UInt(secondsInADay), UInt(secondsInAWeek), UInt(secondsInAMonth_30), UInt(secondsInAYear)]
        let hoursDaysWeeksMonthsOrYear = measurementsRow
        let historyRetentionValue = hoursDaysWeeksMonthsOrYearValue * measuramentsComponentValue[hoursDaysWeeksMonthsOrYear]
        
        return historyRetentionValue
    }
    
    private func historyRetentionToPickerValue(_ historyRetentionValue: UInt) -> (unit: Int, measurement: Int) {
        let hoursModulo = historyRetentionValue % UInt(secondsInAHour)
        let daysModulo = historyRetentionValue % UInt(secondsInADay)
        let weeksModulo = historyRetentionValue % UInt(secondsInAWeek)
        let monthsModulo = historyRetentionValue % UInt(secondsInAMonth_30)
        let yearModulo = historyRetentionValue % UInt(secondsInAYear)
        
        if yearModulo == 0 {
            let year = historyRetentionValue / UInt(secondsInAYear)
            return (Int(year) - 1, HistoryRetentionCustomOption.year.rawValue)
        }
        
        if monthsModulo == 0 {
            let months = historyRetentionValue / UInt(secondsInAMonth_30)
            return (Int(months) - 1, HistoryRetentionCustomOption.months.rawValue)
        }
        
        if weeksModulo == 0 {
            let weeks = historyRetentionValue / UInt(secondsInAWeek)
            return (Int(weeks) - 1, HistoryRetentionCustomOption.weeks.rawValue)
        }
        
        if daysModulo == 0 {
            let days = historyRetentionValue / UInt(secondsInADay)
            return (Int(days) - 1, HistoryRetentionCustomOption.days.rawValue)
        }
        
        if hoursModulo == 0 {
            let hours = historyRetentionValue / UInt(secondsInAHour)
            return (Int(hours) - 1, HistoryRetentionCustomOption.hours.rawValue)
        }
        
        return (0, 0)
    }
}

// MARK: - UIPickerViewDataSource
extension HistoryRetentionPickerViewModel: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
       PickerComponent.totalComponents.rawValue
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        var components: Int = 0
        if component == PickerComponent.units.rawValue {
            components = unitsValuesArray.count
        } else if component == PickerComponent.measurements.rawValue {
            components = measuramentsValuesArray.count
        }
        
        return components
    }
}

// MARK: - UIPickerViewDelegate
extension HistoryRetentionPickerViewModel: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var title: String = ""
        if component == PickerComponent.units.rawValue {
            title = unitsValuesArray[row]
        } else if component == PickerComponent.measurements.rawValue {
            title = measuramentsValuesArray[row]
        }
        
        return title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == PickerComponent.units.rawValue {
            if !shouldChangePickerSelection(pickerView, row) {
                measuramentsValuesArray = (row == 0) ? MeasurementsComponent.singular.values() : MeasurementsComponent.plural.values()
                pickerView.reloadComponent(PickerComponent.measurements.rawValue)
            }
        } else if component == PickerComponent.measurements.rawValue {
            // If the first unit component is selected we have to update the measuments values array to singular
            if pickerView.selectedRow(inComponent: PickerComponent.units.rawValue) == 0 {
                measuramentsValuesArray = MeasurementsComponent.singular.values()
                pickerView.reloadComponent(PickerComponent.measurements.rawValue)
            }
            
            unitsArrayWhenMeasurementChanges(row)
            
            pickerView.reloadComponent(PickerComponent.units.rawValue)
        }
        
        var currentSelectedUnit = pickerView.selectedRow(inComponent: PickerComponent.units.rawValue)
        if  currentSelectedUnit > unitsValuesArray.count {
            let maxUnitForMeasurementValue = unitsValuesArray.count - 1
            currentSelectedUnit = maxUnitForMeasurementValue
        }
        
        let historyRetentionValue = historyRetentionPickerValueToUInt(currentSelectedUnit, pickerView.selectedRow(inComponent: PickerComponent.measurements.rawValue))
        let historyRetentionValueString = NSString.mnz_hoursDaysWeeksMonthsOrYear(from: historyRetentionValue)
        self.invokeCommand?(Command.updateHistoryRetentionLabel(historyRetentionValueString))
    }
    
    private func shouldChangePickerSelection(_ pickerView: UIPickerView, _ row: Int) -> Bool {
        var pickerSelectionChanged = true
        switch row {
        case AutomaticChanges.twelveMonthsToOneYear.rawValue:
            if pickerView.selectedRow(inComponent: PickerComponent.measurements.rawValue) == HistoryRetentionCustomOption.months.rawValue {
                pickerView.selectRow(0, inComponent: PickerComponent.units.rawValue, animated: true)
                pickerView.selectRow(HistoryRetentionCustomOption.year.rawValue, inComponent: PickerComponent.measurements.rawValue, animated: true)
                
                updateComponentsDueAutomaticChange(UnitsComponentValues().year, pickerView)
            }
            
        case AutomaticChanges.twentyFourHoursToOneDay.rawValue:
            if pickerView.selectedRow(inComponent: PickerComponent.measurements.rawValue) == HistoryRetentionCustomOption.hours.rawValue {
                pickerView.selectRow(0, inComponent: PickerComponent.units.rawValue, animated: true)
                pickerView.selectRow(HistoryRetentionCustomOption.days.rawValue, inComponent: PickerComponent.measurements.rawValue, animated: true)
                
                updateComponentsDueAutomaticChange(UnitsComponentValues().days, pickerView)
            }
            
        case AutomaticChanges.thirtyDaysToOneMonth.rawValue:
            if pickerView.selectedRow(inComponent: PickerComponent.measurements.rawValue) == HistoryRetentionCustomOption.days.rawValue {
                pickerView.selectRow(0, inComponent: PickerComponent.units.rawValue, animated: true)
                pickerView.selectRow(HistoryRetentionCustomOption.months.rawValue, inComponent: PickerComponent.measurements.rawValue, animated: true)
                
                updateComponentsDueAutomaticChange(UnitsComponentValues().months, pickerView)
            }
            
        default:
            pickerSelectionChanged = false
        }
        
        return pickerSelectionChanged
    }
    
    private func updateComponentsDueAutomaticChange(_ units: [String], _ pickerView: UIPickerView) {
        unitsValuesArray = units
        measuramentsValuesArray = MeasurementsComponent.singular.values()
        
        pickerView.reloadAllComponents()
    }
    
    private func unitsArrayWhenMeasurementChanges(_ row: Int) {
        switch row {
        case HistoryRetentionCustomOption.hours.rawValue:
            unitsValuesArray = UnitsComponentValues().hours
            
        case HistoryRetentionCustomOption.days.rawValue:
            unitsValuesArray = UnitsComponentValues().days
            
        case HistoryRetentionCustomOption.weeks.rawValue:
            unitsValuesArray = UnitsComponentValues().weeks
            
        case HistoryRetentionCustomOption.months.rawValue:
            unitsValuesArray = UnitsComponentValues().months
            
        case HistoryRetentionCustomOption.year.rawValue:
            unitsValuesArray = UnitsComponentValues().year
            
        default:
            break
        }
    }
}
