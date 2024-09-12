import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationInvitationView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                    .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                
                DetailDisclosureView(
                    text: Strings.Localizable.Meetings.ScheduleMeeting.addParticipants,
                    detail: viewModel.participantsCount > 0 ? String(viewModel.participantsCount) : nil
                ) {
                    viewModel.addParticipantsTap()
                }
                .opacity(viewModel.shouldAllowEditingParticipants ? 1.0 : 0.3)
                .disabled(!viewModel.shouldAllowEditingParticipants)
                
                Divider()
                    .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                    .padding(.leading)
                
                Toggle(isOn: $viewModel.calendarInviteEnabled.onChange { enabled in
                    viewModel.onCalendarInviteEnabledChange(enabled)
                }) {
                    Text(Strings.Localizable.Meetings.ScheduleMeeting.sendCalendarInvite)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .opacity(viewModel.shouldAllowEditingCalendarInvite ? 1.0 : 0.3)
                }
                .frame(minHeight: 44)
                .toggleStyle(SwitchToggleStyle(tint: TokenColors.Support.success.swiftUI))
                .padding(.horizontal)
                .disabled(!viewModel.shouldAllowEditingCalendarInvite)
                
                Divider()
                    .foregroundStyle(TokenColors.Border.subtle.swiftUI)
            }
            .background(TokenColors.Background.page.swiftUI)
            
            ScheduleMeetingCreationFootnoteView(title: Strings.Localizable.Meetings.ScheduleMeeting.CalendarInvite.description)
                .padding(.bottom)
        }
    }
}
