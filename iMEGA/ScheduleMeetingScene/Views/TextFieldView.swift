
import SwiftUI

struct TextFieldView: View {
    @Binding var text: String

    var body: some View {
        TextField(
            Strings.Localizable.Meetings.ScheduleMeeting.MeetingName.placeholder,
            text: $text
        )
        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing
        }
        .padding(.horizontal)
    }
}

@available(iOS 15.0, *)
struct FocusableTextFieldView: View {
    @Binding var text: String
    @FocusState var focused: Bool
    var appearFocused: Bool

    var body: some View {
        TextField(
            Strings.Localizable.Meetings.ScheduleMeeting.MeetingName.placeholder,
            text: $text
        )
        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing
        }
        .padding(.horizontal)
        .focused($focused)
        .onAppear {
            focused = appearFocused
        }
    }
}
