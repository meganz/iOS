import MEGADesignToken
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
                .foregroundColor(TokenColors.Text.secondary.swiftUI)
                .padding(.horizontal)
            Divider()
        }
    }
}
