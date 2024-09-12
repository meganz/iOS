import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ScheduleMeetingCreationNameView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    var appearFocused: Bool

    var body: some View {
        VStack {
            Divider()
            
            FocusableTextFieldView(
                placeholder: Strings.Localizable.Meetings.ScheduleMeeting.MeetingName.placeholder,
                text: $viewModel.meetingName,
                appearFocused: appearFocused,
                clearButtonMode: .whileEditing
            )
            .padding(.horizontal)
            .opacity(viewModel.shouldAllowEditingRecurrenceOption ? 1.0 : 0.3)
            .disabled(!viewModel.shouldAllowEditingMeetingName)

            Divider()
        }
        .background(TokenColors.Background.surface1.swiftUI)
    }
}
