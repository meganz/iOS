import SwiftUI

struct ScheduleMeetingCreationMonthlyCustomOptionsView: View {
    private struct constants {
        static let days = (1...31).compactMap(String.init)
        static let rows = 5
        static let columns = 7
        static let columnPadding = 2
        static let allowsMultipleSelection = false
    }
    
    @ObservedObject var viewModel: ScheduleMeetingCreationMonthlyCustomOptionsViewModel
    
    var selectedDays: Binding<Set<String>> {
        Binding {
           viewModel.selectedDays
       } set: {
           viewModel.updateSelectedMonthDayList($0.compactMap(Int.init))
       }
    }
    
    var body: some View {
        Group {
            ForEach(viewModel.monthlyCustomOptions, id: \.self) { optionName in
                ScheduleMeetingCreationOptionSelectionView(
                    name: optionName,
                    isSelected: viewModel.selectedCustomOption == optionName
                ) {
                    viewModel.resetSelection(to: optionName)
                }
            }
            
            if viewModel.selectedCustomOption == viewModel.monthlyCustomOptions.first {
                ScheduleMeetingCreationMonthlyDatePickerView(
                    days: constants.days,
                    rows: constants.rows,
                    columns: constants.columns,
                    columnPadding: constants.columnPadding,
                    allowsMultipleSelection: constants.allowsMultipleSelection,
                    selectedDays: selectedDays
                )
            } else {
                ScheduleMeetingCreationMonthlyCustomPickerView(viewModel: viewModel)
            }
        }
    }
}

struct ScheduleMeetingCreationMonthlyCustomPickerView: View {
    @ObservedObject var viewModel: ScheduleMeetingCreationMonthlyCustomOptionsViewModel
    
    @State private var selectedWeekNumber: String = ""
    @State private var selectedWeekSymbol: String = ""
    
    var body: some View {
        HStack(spacing: 0) {
            Picker(
                Strings.Localizable.Meetings.ScheduleMeeting.Create.WeekNumber.Picker.accessibilityLabel,
                selection: $selectedWeekNumber
            ) {
                ForEach(viewModel.weekNumbers, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.wheel)
            .onChange(of: selectedWeekNumber) { newValue in
                viewModel.selected(weekNumber: newValue, andWeekDay: selectedWeekSymbol)
            }
            
            Picker(
                Strings.Localizable.Meetings.ScheduleMeeting.Create.WeekDay.Picker.accessibilityLabel,
                selection: $selectedWeekSymbol
            ) {
                ForEach(viewModel.weekdaySymbols, id: \.self) { weekSymbol in
                    Text(weekSymbol)
                }
            }
            .pickerStyle(.wheel)
            .onChange(of: selectedWeekSymbol) { newValue in
                viewModel.selected(weekNumber: selectedWeekNumber, andWeekDay: newValue)
            }
        }
        .onAppear {
            selectedWeekNumber = viewModel.selectedWeekNumber ?? viewModel.weekNumbers.first ?? ""
            selectedWeekSymbol = viewModel.selectedWeekSymbol ?? viewModel.weekdaySymbols.first ?? ""
        }
    }
}

// https://stackoverflow.com/questions/56961550/swiftui-placing-two-pickers-side-by-side-in-hstack-does-not-resize-pickers/72409644#72409644
// https://developer.apple.com/forums/thread/687986?answerId=706782022#706782022
// Using two pickers inside a HStack (ScheduleMeetingCreationMonthlyCustomPickerView) seems to have UI issue. The below code is a workaround for fixing the issue.
extension UIPickerView {
    open override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: super.intrinsicContentSize.height)
    }
}
