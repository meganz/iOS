
import SwiftUI

struct ScheduleMeetingCreationInvitationView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
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
    }
}
