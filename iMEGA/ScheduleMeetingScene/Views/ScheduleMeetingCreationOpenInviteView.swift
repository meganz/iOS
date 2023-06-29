
import SwiftUI

struct ScheduleMeetingCreationOpenInviteView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Divider()
            
            Toggle(isOn: $viewModel.allowNonHostsToAddParticipantsEnabled) {
                Text(Strings.Localizable.Meetings.ScheduleMeeting.openInvite)
                    .opacity(viewModel.shouldAllowEditingAllowNonHostsToAddParticipants ? 1.0 : 0.3)
            }
            .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
            .padding(.horizontal)
            .disabled(!viewModel.shouldAllowEditingAllowNonHostsToAddParticipants)
            
            Divider()
        }
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
        .padding(.vertical)
    }
}
