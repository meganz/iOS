
import SwiftUI

struct ScheduleMeetingView: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var viewModel: ScheduleMeetingViewModel

    var body: some View {
        ScrollView {
            //Name
            VStack {
                Divider()
                TextFieldView(text: $viewModel.meetingName)
                Divider()
                
            }
            .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
            
            if viewModel.meetingNameTooLong {
                ErrorView(error: Strings.Localizable.Meetings.ScheduleMeeting.MeetingName.lenghtError)
            }
            
            //Start, end, recurrence and link
            VStack {
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
                    DetailDisclosureView(text: Strings.Localizable.Meetings.ScheduleMeeting.recurrence, detail: Strings.Localizable.never) {
                        
                    }
                    Divider()
                        .padding(.leading)
                    Toggle(Strings.Localizable.Meetings.ScheduleMeeting.link, isOn: $viewModel.meetingLinkEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
                        .padding(.horizontal)
                    Divider()
                }
                .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
                Text(Strings.Localizable.Meetings.ScheduleMeeting.Link.description)
                    .font(.footnote)
                    .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.mnz_gray3C3C43()).opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            
            //Add participants, calendar invite
            VStack {
                Divider()
                DetailDisclosureView(text: Strings.Localizable.Meetings.ScheduleMeeting.addParticipants, detail: viewModel.participantsCount > 0 ? String(viewModel.participantsCount) : nil) {
                    viewModel.addParticipantsTap()
                }
                Divider()
                    .padding(.leading)
                Toggle(Strings.Localizable.Meetings.ScheduleMeeting.sendCalendarInvite, isOn: $viewModel.calendarInviteEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
                    .padding(.horizontal)
                Divider()
            }
            .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)

            //Open invite
            VStack {
                Divider()
                Toggle(Strings.Localizable.Meetings.ScheduleMeeting.openInvite, isOn: $viewModel.allowNonHostsToAddParticipantsEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
                    .padding(.horizontal)
                Divider()
            }
            .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
            .padding(.vertical)

            //Description
            VStack {
                VStack {
                    Divider()
                    TextDescriptionView(descriptionText: $viewModel.meetingDescription)
                    Divider()
                }
                .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
                
                if viewModel.meetingDescriptionTooLong {
                    ErrorView(error: Strings.Localizable.Meetings.ScheduleMeeting.Description.lenghtError)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(.vertical)
        .background(colorScheme == .dark ? .black : Color(Colors.General.White.f7F7F7.name))
        .ignoresSafeArea(.container, edges: [.top, .bottom])
        .actionSheet(isPresented: $viewModel.showDiscardAlert) {
            ActionSheet(title: Text(Strings.Localizable.Meetings.ScheduleMeeting.DiscardChanges.title), buttons: discardChangesButtons())
        }
    }
    
    private func discardChangesButtons() -> [ActionSheet.Button] {
        return [
            ActionSheet.Button.default(Text(Strings.Localizable.Meetings.ScheduleMeeting.DiscardChanges.confirm)) {
                viewModel.discardChangesTap()
            },
            ActionSheet.Button.cancel(Text(Strings.Localizable.Meetings.ScheduleMeeting.DiscardChanges.cancel)) {
                viewModel.keepEditingTap()
            }
        ]
    }
}
