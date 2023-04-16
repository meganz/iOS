
import SwiftUI

struct TextDescriptionView: View {
    @Binding var descriptionText: String

    var body: some View {
        if #available(iOS 16.0, *) {
            TextField(
                Strings.Localizable.Meetings.ScheduleMeeting.description,
                text: $descriptionText,
                axis: .vertical
            )
            .padding(.horizontal)
        } else {
            TextField(
                Strings.Localizable.Meetings.ScheduleMeeting.description,
                text: $descriptionText
            )
            .padding(.horizontal)
        }
    }
}

@available(iOS 15.0, *)
struct FocusableTextDescriptionView: View {
    @Binding var descriptionText: String
    @FocusState var focused: Bool
    
    let onChange: (Bool) -> Void

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                TextField(
                    Strings.Localizable.Meetings.ScheduleMeeting.description,
                    text: $descriptionText,
                    axis: .vertical
                )
                .padding(.horizontal)
            } else {
                TextField(
                    Strings.Localizable.Meetings.ScheduleMeeting.description,
                    text: $descriptionText
                )
                .padding(.horizontal)
            }
        }
        .focused($focused)
        .onChange(of: focused) { isFocused in
            onChange(isFocused)
        }
    }
}
