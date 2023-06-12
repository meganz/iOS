import SwiftUI

struct ScheduleMeetingEndRecurrenceOptionsView: View {
    @StateObject var viewModel: ScheduleMeetingEndRecurrenceOptionsViewModel
    
    var body: some View {
        List {
            Section {
                RecurrenceOptionView(
                    name: Strings.Localizable.Meetings.ScheduleMeeting.Create.EndRecurrence.Option.never,
                    isSelected: viewModel.rules.until == nil
                ) {
                    viewModel.endRecurrenceNeverSelected()
                }
                RecurrenceOptionView(
                    name: Strings.Localizable.Meetings.ScheduleMeeting.Create.EndRecurrence.Option.onDate,
                    isSelected: viewModel.rules.until != nil
                ) {
                    viewModel.endRecurrenceSelected()
                }
                if viewModel.rules.until != nil {
                    HStack {
                        Spacer()
                        DatePicker(
                            "",
                            selection: $viewModel.endRecurrenceDate,
                            in: viewModel.startDate...,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .datePickerStyle(.wheel)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(Strings.Localizable.Meetings.ScheduleMeeting.Create.EndRecurrence.title)
    }
}
