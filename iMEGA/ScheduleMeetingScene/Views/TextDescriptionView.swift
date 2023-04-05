
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
