
import SwiftUI

struct ScheduleMeetingCreationInvitationView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Divider()
            
            DetailDisclosureView(
                text: Strings.Localizable.Meetings.ScheduleMeeting.addParticipants,
                detail: viewModel.participantsCount > 0 ? String(viewModel.participantsCount) : nil
            ) {
                viewModel.addParticipantsTap()
            }
            .opacity(viewModel.shouldAllowEditingParticipants ? 1.0 : 0.3)
            .disabled(!viewModel.shouldAllowEditingParticipants)
            
            Divider()
                .padding(.leading)
            
            Toggle(isOn: $viewModel.calendarInviteEnabled) {
                Text(Strings.Localizable.Meetings.ScheduleMeeting.sendCalendarInvite)
                    .opacity(viewModel.shouldAllowEditingCalendarInvite ? 1.0 : 0.3)
            }
            .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
            .padding(.horizontal)
            .disabled(!viewModel.shouldAllowEditingCalendarInvite)

            Divider()
        }
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
    }
}
