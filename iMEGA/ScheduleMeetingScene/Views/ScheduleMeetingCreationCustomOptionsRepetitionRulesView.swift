import SwiftUI

struct ScheduleMeetingCreationCustomOptionsRepetitionRulesView: View {
    @ObservedObject var viewModel: ScheduleMeetingCreationCustomOptionsViewModel
    @State var selectedInterval: Int
    
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
                    selection: $selectedInterval,
                    convertOptionToString: { "\(viewModel.string(forInterval: $0) ?? "")" }
                )
                .onChange(of: selectedInterval) { updatedInterval in
                    viewModel.update(interval: updatedInterval)
                }
            }
        }
    }
}
