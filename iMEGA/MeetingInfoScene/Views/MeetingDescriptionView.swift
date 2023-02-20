import SwiftUI

struct MeetingDescriptionView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let description: String

    var body: some View {
        VStack (alignment: .leading) {
            Divider()
            Text(Strings.Localizable.Meetings.Info.descriptionLabel)
                .font(.body)
                .padding(.horizontal)
            Text(description)
                .font(.body)
                .foregroundColor(Color(colorScheme == .dark ? UIColor.mnz_grayEBEBF5() : UIColor.mnz_gray3C3C43()).opacity(0.6))
                .padding(.horizontal)
            Divider()
        }
        .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
    }
}
