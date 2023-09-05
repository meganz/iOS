import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationPropertiesView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
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
            
            ScheduleMeetingCreationFootnoteView(title: Strings.Localizable.Meetings.ScheduleMeeting.Link.description)
                .opacity(viewModel.shouldAllowEditingMeetingLink ? 1.0 : 0.3)
        }
        .padding(.vertical)
    }
}
