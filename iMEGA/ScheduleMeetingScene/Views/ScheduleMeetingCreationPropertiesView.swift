import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationPropertiesView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ScheduleMeetingCreationDateAndRecurrenceView(viewModel: viewModel)
                Toggle(isOn: $viewModel.meetingLinkEnabled.onChange { enabled in
                    viewModel.onMeetingLinkEnabledChange(enabled)
                }) {
                    Text(Strings.Localizable.Meetings.ScheduleMeeting.link)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                        .opacity(viewModel.shouldAllowEditingMeetingLink ? 1.0 : 0.3)
                }
                .frame(minHeight: 44)
                .toggleStyle(SwitchToggleStyle(tint: isDesignTokenEnabled
                                               ? TokenColors.Support.success.swiftUI
                                               : Color(UIColor.mnz_green00A886())))
                .padding(.horizontal)
                .disabled(
                    !viewModel.meetingLinkToggleUIEnabled
                    || !viewModel.shouldAllowEditingMeetingLink
                )
                Divider()
                    .foregroundStyle(TokenColors.Border.subtle.swiftUI)
            }
            .background(isDesignTokenEnabled
                        ? TokenColors.Background.page.swiftUI
                        : colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._FFFFFF.color)
            
            ScheduleMeetingCreationFootnoteView(title: Strings.Localizable.Meetings.ScheduleMeeting.Link.description)
                .opacity(viewModel.shouldAllowEditingMeetingLink ? 1.0 : 0.3)
        }
        .padding(.vertical)
    }
}
