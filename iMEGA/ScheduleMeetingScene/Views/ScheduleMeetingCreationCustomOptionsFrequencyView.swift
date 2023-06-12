import SwiftUI

struct ScheduleMeetingCreationCustomOptionsFrequencyView: View {
    @ObservedObject var viewModel: ScheduleMeetingCreationCustomOptionsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ScheduleMeetingCreationCustomOptionsSelectionHeaderView(
                title: Strings.Localizable.Meetings.ScheduleMeeting.Create.Frequency.optionTitle,
                selectedText: viewModel.selectedFrequencyName,
                isExpanded: viewModel.expandFrequency
            ) {
                viewModel.toggleFrequencyOption()
            }
            
            if viewModel.expandFrequency {
                ScheduleMeetingCreationCustomOptionsWheelPickerView(
                    label: Strings.Localizable.Meetings.ScheduleMeeting.Create.Frequency.Picker.accessibilityLabel,
                    options: viewModel.frequencyNames,
                    selection: $viewModel.selectedFrequencyName,
                    convertOptionToString: { $0 }
                )
            }
        }
    }
}
