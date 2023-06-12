import SwiftUI

struct ScheduleMeetingCreationMonthlyCustomOptionsView: View {
    @ObservedObject var viewModel: ScheduleMeetingCreationMonthlyCustomOptionsViewModel
    @State private var selectedOption = ""
    @State private var selectedDates: Set<String> = []

    var body: some View {
        Group {
            ForEach(viewModel.monthlyCustomOptions, id: \.self) { optionName in
                ScheduleMeetingCreationOptionSelectionView(name: optionName, isSelected: selectedOption == optionName)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedOption = optionName
                        viewModel.resetSelection(to: selectedOption)
                    }
            }
            
            if selectedOption == viewModel.monthlyCustomOptions.first {
                ScheduleMeetingCreationMonthlyCustomPickerView(viewModel: viewModel)
            } else {
                ScheduleMeetingCreationMonthlyDatePickerView(
                    days: (1...31).map { "\($0)"},
                    rows: 5,
                    columns: 7,
                    columnPadding: 2,
                    allowsMultipleSelection: false,
                    selectedDays: $selectedDates
                )
                .onChange(of: selectedDates) { newValue in
                    viewModel.updateSelectedMonthDayList( newValue.compactMap { Int($0) })
                }
            }
        }
        .onAppear {
            selectedOption = viewModel.selectedCustomOption()
            selectedDates = viewModel.selectedDates()
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
