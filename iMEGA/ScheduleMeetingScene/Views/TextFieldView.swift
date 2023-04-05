
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
