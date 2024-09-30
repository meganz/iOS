import MEGADesignToken
import MEGAL10n
import SwiftUI

struct ScheduleMeetingCreationDescriptionView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Binding var isBottomViewInFocus: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Divider()
                    .foregroundStyle(TokenColors.Border.subtle.swiftUI)
                
                FocusableTextDescriptionView(descriptionText: $viewModel.meetingDescription) { isBottomViewInFocus = $0 }
                .opacity(viewModel.shouldAllowEditingMeetingDescription ? 1.0 : 0.3)
                .disabled(!viewModel.shouldAllowEditingMeetingDescription)
                .frame(minHeight: 44)
                Divider()
                    .foregroundStyle(TokenColors.Border.subtle.swiftUI)
            }
            .background(TokenColors.Background.surface1.swiftUI)
            
            if viewModel.meetingDescriptionTooLong {
                ErrorView(error: Strings.Localizable.Meetings.ScheduleMeeting.Description.lenghtError)
            }
        }
        .padding(.bottom, 20)
    }
}
