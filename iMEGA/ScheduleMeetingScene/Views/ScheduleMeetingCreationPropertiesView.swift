
import SwiftUI

struct ScheduleMeetingCreationPropertiesView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                VStack {
                    ScheduleMeetingCreationDateAndRecurrenceView(
                        viewModel: viewModel,
                        showMonthlyRecurrenceFootnoteView: viewModel.showMonthlyRecurrenceFootnoteView
                    )
                    Toggle(Strings.Localizable.Meetings.ScheduleMeeting.link, isOn: $viewModel.meetingLinkEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.mnz_green00A886())))
                        .padding(.horizontal)
                    Divider()
                }
                .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
                
                ScheduleMeetingCreationLinkFootnoteView()
            }
            .padding(.vertical)
            
            ScheduleMeetingCreationInvitationView(viewModel: viewModel)
        }
    }
}
