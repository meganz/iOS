import SwiftUI

struct ScheduleMeetingCreationFootnoteView: View {
    let title: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(title)
            .font(.footnote)
            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.gray3C3C43).opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }
}

struct ScheduleMeetingCreationFootnoteView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleMeetingCreationFootnoteView(title: "Email a calendar invite to participants so they can add the meeting to their calendars.")
            .padding(20)
            .previewLayout(.sizeThatFits)
    }
}
