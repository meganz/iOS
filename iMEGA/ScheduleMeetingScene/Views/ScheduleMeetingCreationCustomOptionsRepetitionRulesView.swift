import SwiftUI

struct ScheduleMeetingCreationCustomOptionsRepetitionRulesView: View {
    @ObservedObject var viewModel: ScheduleMeetingCreationCustomOptionsViewModel
    
    var selectedInterval: Binding<Int> {
        Binding {
            viewModel.interval
        } set: {
            viewModel.update(interval: $0)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScheduleMeetingCreationCustomOptionsSelectionHeaderView(
                title: Strings.Localizable.Meetings.ScheduleMeeting.Create.Interval.optionTitle,
                selectedText: viewModel.string(forInterval: viewModel.interval) ?? "",
                isExpanded: viewModel.expandInterval
            ) {
                viewModel.toggleIntervalOption()
            }
            
            if viewModel.expandInterval, let intervalOptions = viewModel.intervalOptions {
                Divider()
                    .padding(.vertical)
                ScheduleMeetingCreationCustomOptionsWheelPickerView(
                    label: Strings.Localizable.Meetings.ScheduleMeeting.Create.Interval.Picker.accessibilityLabel,
                    options: intervalOptions,
                    selection: selectedInterval,
                    convertOptionToString: { "\(viewModel.string(forInterval: $0) ?? "")" }
                )
            }
        }
    }
}
