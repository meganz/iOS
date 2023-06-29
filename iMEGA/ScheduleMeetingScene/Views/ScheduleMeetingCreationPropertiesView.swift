
import SwiftUI

struct ScheduleMeetingCreationPropertiesView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                VStack {
                    ScheduleMeetingCreationDateAndRecurrenceView(viewModel: viewModel)
                    Toggle(isOn: $viewModel.meetingLinkEnabled) {
                        Text(Strings.Localizable.Meetings.ScheduleMeeting.link)
                            .opacity(viewModel.shouldAllowEditingMeetingLink ? 1.0 : 0.3)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
                    .padding(.horizontal)
                    .disabled(
                        !viewModel.meetingLinkToggleUIEnabled
                        || !viewModel.shouldAllowEditingMeetingLink
                    )
                    Divider()
                }
                .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
                
                ScheduleMeetingCreationLinkFootnoteView()
                    .opacity(viewModel.shouldAllowEditingMeetingLink ? 1.0 : 0.3)
            }
            .padding(.vertical)
            
            ScheduleMeetingCreationInvitationView(viewModel: viewModel)
        }
    }
}
