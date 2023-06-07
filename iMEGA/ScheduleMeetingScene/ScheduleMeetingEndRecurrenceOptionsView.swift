import SwiftUI

struct ScheduleMeetingEndRecurrenceOptionsView: View {
    @StateObject var viewModel: ScheduleMeetingEndRecurrenceOptionsViewModel
    
    var body: some View {
        List {
            Section {
                RecurrenceOptionView(name: Strings.Localizable.Meetings.ScheduleMeeting.Create.EndRecurrence.Option.never, isSelected: viewModel.rules.until == nil)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.endRecurrenceNeverSelected()
                    }
                RecurrenceOptionView(name: Strings.Localizable.Meetings.ScheduleMeeting.Create.EndRecurrence.Option.onDate, isSelected: viewModel.rules.until != nil)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.endRecurrenceSelected()
                    }
                if viewModel.rules.until != nil {
                    DatePicker(
                        "",
                        selection: $viewModel.endRecurrenceDate,
                        in: Date()...,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle(Strings.Localizable.Meetings.ScheduleMeeting.Create.EndRecurrence.title)
    }
}
