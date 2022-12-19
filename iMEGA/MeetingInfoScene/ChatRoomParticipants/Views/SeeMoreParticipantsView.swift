import SwiftUI

struct SeeMoreParticipantsView: View {
    @Environment(\.colorScheme) private var colorScheme

    private enum Constants {
        static let viewPadding: CGFloat = 10
        static let viewHeight: CGFloat = 44
        static let imageSize = CGSize(width: 60, height: 60)
        static let spacing: CGFloat = 0
        static let rotation: CGFloat = 90
        static let disclosureOpacity: CGFloat = 0.6
    }
    
    private let discolureIndicator = "chevron.right"
    
    var body: some View {
        VStack (spacing: Constants.spacing) {
            HStack {
                Image(systemName: discolureIndicator)
                    .foregroundColor(.gray.opacity(Constants.disclosureOpacity))
                    .rotationEffect(.degrees(Constants.rotation))
                    .padding(.horizontal)
                Text(Strings.Localizable.Meetings.Info.Participants.seeAll)
                    .font(.body)
                Spacer()
            }
            .padding(.trailing, Constants.viewPadding)
            .frame(height: Constants.viewHeight)
            .contentShape(Rectangle())
            .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
            Divider()
        }
    }
}
