
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
                    detail: viewModel.selectedFrequencyDetails(),
                    verticalAlignment: .top,
                    action: viewModel.showRecurrenceOptionsView
                )
                .opacity(viewModel.shouldAllowEditingRecurrenceOption ? 1.0 : 0.3)
                .disabled(!viewModel.shouldAllowEditingRecurrenceOption)
                
                if viewModel.rules.frequency != .invalid {
                    Divider()
                        .padding(.leading)
                    
                    DetailDisclosureView(
                        text: Strings.Localizable.Meetings.ScheduleMeeting.Create.EndRecurrence.title,
                        detail: viewModel.endRecurrenceDetailText(),
                        action: viewModel.showEndRecurrenceOptionsView
                    )
                    .opacity(viewModel.shouldAllowEditingEndRecurrenceOption ? 1.0 : 0.3)
                    .disabled(!viewModel.shouldAllowEditingEndRecurrenceOption)
                }

                Divider()
                    .padding(.leading)
            }
            
            if let monthlyRecurrenceFootnoteViewText = viewModel.monthlyRecurrenceFootnoteViewText {
                ScheduleMeetingMonthlyRecurrenceFootnoteView(text: monthlyRecurrenceFootnoteViewText)
                    .opacity(viewModel.shouldAllowEditingRecurrenceOption ? 1.0 : 0.6)

                Divider()
                    .padding(.leading)
            }
            
        }
    }
}
