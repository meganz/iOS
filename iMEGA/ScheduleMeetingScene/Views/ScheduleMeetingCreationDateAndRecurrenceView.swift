
import SwiftUI

struct ScheduleMeetingCreationDateAndRecurrenceView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Divider()
                DatePickerView(title: Strings.Localizable.Meetings.ScheduleMeeting.start, dateFormatted: $viewModel.startDateFormatted, datePickerVisible: $viewModel.startDatePickerVisible, date: $viewModel.startDate, dateRange: Date()...) {
                    viewModel.startsDidTap()
                }
                if viewModel.startDatePickerVisible {
                    Divider()
                } else {
                    Divider()
                        .padding(.leading)
                }
                DatePickerView(title: Strings.Localizable.Meetings.ScheduleMeeting.end, dateFormatted: $viewModel.endDateFormatted, datePickerVisible: $viewModel.endDatePickerVisible, date: $viewModel.endDate, dateRange: viewModel.minimunEndDate...) {
                    viewModel.endsDidTap()
                }
                if viewModel.endDatePickerVisible {
                    Divider()
                } else {
                    Divider()
                        .padding(.leading)
                }
                DetailDisclosureView(
                    text: Strings.Localizable.Meetings.ScheduleMeeting.recurrence,
                    detail: viewModel.recurrenceOptionText(),
                    action: viewModel.showRecurrenceOptionsView
                )
                
                if viewModel.rules.frequency != .invalid {
                    Divider()
                        .padding(.leading)
                    DetailDisclosureView(
                        text: Strings.Localizable.Meetings.ScheduleMeeting.Create.EndRecurrence.title,
                        detail: viewModel.endRecurrenceDetailText(),
                        action: viewModel.showEndRecurrenceOptionsView
                    )
                }

                Divider()
                    .padding(.leading)
            }
            
            if let monthlyRecurrenceFootnoteViewText = viewModel.monthlyRecurrenceFootnoteViewText {
                ScheduleMeetingMonthlyRecurrenceFootnoteView(text: monthlyRecurrenceFootnoteViewText)
                Divider()
                    .padding(.leading)
            }
            
        }
    }
}
