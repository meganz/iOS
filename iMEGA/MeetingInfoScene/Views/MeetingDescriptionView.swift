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
                .foregroundColor(foregroundColor)
                .padding(.horizontal)
            Divider()
        }
    }
    
    private var foregroundColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Text.secondary.swiftUI
        } else {
            Color(
                colorScheme == .dark ? 
                UIColor.grayEBEBF5 :
                UIColor.gray3C3C43).opacity(0.6
            )
        }
    }
}
