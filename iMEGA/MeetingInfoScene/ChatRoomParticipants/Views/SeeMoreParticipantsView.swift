import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct SeeMoreParticipantsView: View {
    @Environment(\.colorScheme) private var colorScheme

    private enum Constants {
        static let viewPadding: CGFloat = 10
        static let viewHeight: CGFloat = 44
        static let imageSize = CGSize(width: 60, height: 60)
        static let spacing: CGFloat = 0
        static let rotationRight: CGFloat = 90
        static let rotationLeft: CGFloat = -90
        static let disclosureOpacity: CGFloat = 0.6
    }
    
    private let disclosureIndicator = "chevron.right"
    
    let isExpanded: Bool

    var body: some View {
        VStack(spacing: Constants.spacing) {
            HStack {
                Image(systemName: disclosureIndicator)
                    .foregroundColor(foregroundColor)
                    .rotationEffect(.degrees(isExpanded ? Constants.rotationLeft : Constants.rotationRight))
                    .padding(.horizontal)
                Text(isExpanded ? Strings.Localizable.Meetings.Info.Participants.seeLess : Strings.Localizable.Meetings.Info.Participants.seeMore)
                    .font(.body)
                Spacer()
            }
            .padding(.trailing, Constants.viewPadding)
            .frame(height: Constants.viewHeight)
            .contentShape(Rectangle())
            .designTokenBackground(isDesignTokenEnabled, legacyColor: legacyBackgroundColor)
            Divider()
        }
    }
    
    private var foregroundColor: Color {
        if isDesignTokenEnabled {
            TokenColors.Text.secondary.swiftUI
        } else {
            Color(UIColor.gray8E8E93).opacity(Constants.disclosureOpacity)
        }
    }
    
    private var legacyBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.black1C1C1E) : Color(UIColor.whiteFFFFFF)
    }
}
