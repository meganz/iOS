import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationPropertiesView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ScheduleMeetingCreationDateAndRecurrenceView(viewModel: viewModel)
                Toggle(isOn: $viewModel.meetingLinkEnabled.onChange { enabled in
                    Task { @MainActor in
                        viewModel.onMeetingLinkEnabledChange(enabled)
                    }
                }) {
                    Text(Strings.Localizable.Meetings.ScheduleMeeting.link)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .opacity(viewModel.shouldAllowEditingMeetingLink ? 1.0 : 0.3)
                }
                .frame(minHeight: 44)
                .toggleStyle(SwitchToggleStyle(tint: TokenColors.Support.success.swiftUI))
                .padding(.horizontal)
                .disabled(
                    !viewModel.meetingLinkToggleUIEnabled
                    || !viewModel.shouldAllowEditingMeetingLink
                )
                Divider()
                    .foregroundStyle(TokenColors.Border.subtle.swiftUI)
            }
            .background(TokenColors.Background.page.swiftUI)
            
            ScheduleMeetingCreationFootnoteView(title: Strings.Localizable.Meetings.ScheduleMeeting.Link.description)
                .opacity(viewModel.shouldAllowEditingMeetingLink ? 1.0 : 0.3)
        }
        .padding(.vertical)
    }
}
