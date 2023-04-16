
import SwiftUI

struct ScheduleMeetingCreationOpenInviteView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack {
            Divider()
            Toggle(Strings.Localizable.Meetings.ScheduleMeeting.openInvite, isOn: $viewModel.allowNonHostsToAddParticipantsEnabled)
                .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
                .padding(.horizontal)
            Divider()
        }
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
        .padding(.vertical)
    }
}

