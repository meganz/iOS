import SwiftUI

struct ScheduleMeetingMonthlyRecurrenceFootnoteView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Text(Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.footNote)
            .font(.footnote)
            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color(UIColor.mnz_gray3C3C43()).opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 20)
            .background(colorScheme == .dark ? .black : Color(Colors.General.White.f7F7F7.name))

    }
}
