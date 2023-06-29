
import SwiftUI

struct ScheduleMeetingCreationNameView: View {
    @ObservedObject var viewModel: ScheduleMeetingViewModel
    @Environment(\.colorScheme) private var colorScheme
    var appearFocused: Bool

    var body: some View {
        VStack {
            Divider()
            Group {
                if #available(iOS 15.0, *) {
                    FocusableTextFieldView(text: $viewModel.meetingName, appearFocused: appearFocused)
                } else {
                    TextFieldView(text: $viewModel.meetingName)
                }
            }
            .opacity(viewModel.shouldAllowEditingRecurrenceOption ? 1.0 : 0.3)
            .disabled(!viewModel.shouldAllowEditingMeetingName)

            Divider()
        }
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
    }
}
