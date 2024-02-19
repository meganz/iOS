import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationOpenInviteView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundStyle(TokenColors.Border.subtle.swiftUI)
            
            Toggle(isOn: $viewModel.allowNonHostsToAddParticipantsEnabled.onChange { enabled in
                viewModel.onAllowNonHostsToAddParticipantsEnabledChange(enabled)
            }) {
                Text(Strings.Localizable.Meetings.ScheduleMeeting.openInvite)
                    .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    .opacity(viewModel.shouldAllowEditingAllowNonHostsToAddParticipants ? 1.0 : 0.3)
            }
            .frame(minHeight: 44)
            .toggleStyle(SwitchToggleStyle(tint: isDesignTokenEnabled
                                           ? TokenColors.Support.success.swiftUI
                                           : Color(UIColor.mnz_green00A886())))
            .padding(.horizontal)
            .disabled(!viewModel.shouldAllowEditingAllowNonHostsToAddParticipants)
            
            Divider()
                .foregroundStyle(TokenColors.Border.subtle.swiftUI)
        }
        .background(isDesignTokenEnabled
                    ? TokenColors.Background.page.swiftUI
                    : colorScheme == .dark ? MEGAAppColor.Black._1C1C1E.color : MEGAAppColor.White._FFFFFF.color)
        .padding(.bottom)
    }
}
