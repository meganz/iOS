import SwiftUI

struct ScheduleMeetingCreationLinkFootnoteView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(Strings.Localizable.Meetings.ScheduleMeeting.Link.description)
            .font(.footnote)
            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.mnz_gray3C3C43()).opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
}

