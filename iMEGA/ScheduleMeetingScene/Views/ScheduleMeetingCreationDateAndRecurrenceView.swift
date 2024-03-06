import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationDateAndRecurrenceView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                    .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                
                DatePickerView(title: Strings.Localizable.Meetings.ScheduleMeeting.start, dateFormatted: $viewModel.startDateFormatted, datePickerVisible: $viewModel.startDatePickerVisible, date: $viewModel.startDate, dateRange: Date()...) {
                    viewModel.startsDidTap()
                }
                if viewModel.startDatePickerVisible {
                    Divider()
                        .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                } else {
                    Divider()
                        .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                        .padding(.leading)
                }
                DatePickerView(title: Strings.Localizable.Meetings.ScheduleMeeting.end, dateFormatted: $viewModel.endDateFormatted, datePickerVisible: $viewModel.endDatePickerVisible, date: $viewModel.endDate, dateRange: viewModel.minimunEndDate...) {
                    viewModel.endsDidTap()
                }
                
               if viewModel.showLimitDurationView {
                    BannerView(
                        config: .init(
                            copy: Strings.Localizable.Meetings.ScheduleMeeting.Create.FreePlanLimitWarning.longerThan60Minutes,
                            theme: .light,
                            tapAction: viewModel.upgradePlansViewTapped
                        )
                    )
                    .font(.footnote)
               }

                if viewModel.endDatePickerVisible || viewModel.showLimitDurationView {
                    Divider()
                        .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                } else {
                    Divider()
                        .foregroundStyle(TokenColors.Border.subtle.swiftUI)
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
                        .foregroundStyle(TokenColors.Border.subtle.swiftUI)
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
                    .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                    .padding(.leading)
            }
            
            if let monthlyRecurrenceFootnoteViewText = viewModel.monthlyRecurrenceFootnoteViewText {
                ScheduleMeetingMonthlyRecurrenceFootnoteView(text: monthlyRecurrenceFootnoteViewText)
                    .opacity(viewModel.shouldAllowEditingRecurrenceOption ? 1.0 : 0.6)

                Divider()
                    .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                    .padding(.leading)
            }
            
        }
    }
}
