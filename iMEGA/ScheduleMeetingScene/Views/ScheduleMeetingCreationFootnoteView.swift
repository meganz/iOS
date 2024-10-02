import MEGADesignToken
import SwiftUI

struct ScheduleMeetingCreationFootnoteView: View {
    let title: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(title)
            .font(.footnote)
            .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 6)
    }
}

@available(iOS 17.0, *)
#Preview(traits: .sizeThatFitsLayout) {
    ScheduleMeetingCreationFootnoteView(title: "Email a calendar invite to participants so they can add the meeting to their calendars.")
        .padding(20)
}
