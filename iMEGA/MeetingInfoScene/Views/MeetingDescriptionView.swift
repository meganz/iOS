import MEGAL10n
import SwiftUI

struct MeetingDescriptionView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let description: String

    var body: some View {
        VStack(alignment: .leading) {
            Divider()
            Text(Strings.Localizable.Meetings.Info.descriptionLabel)
                .font(.body)
                .padding(.horizontal)
            Text(description)
                .font(.body)
                .foregroundColor(Color(colorScheme == .dark ? MEGAAppColor.Gray._EBEBF5.uiColor : MEGAAppColor.Gray._3C3C43.uiColor).opacity(0.6))
                .padding(.horizontal)
            Divider()
        }
        .background(colorScheme == .dark ? Color(.black1C1C1E) : .white)
    }
}
