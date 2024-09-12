import MEGADesignToken
import SwiftUI

struct OccurrenceView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let occurrence: ScheduleMeetingOccurrence
    let chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
    
    private enum Constants {
        static let headerHeight: CGFloat = 28
        static let rowHeight: CGFloat = 65
        static let avatarSize = CGSize(width: 28, height: 28)
        static let spacing: CGFloat = 0
        static let headerSpacing: CGFloat = 4
        static let headerBackgroundOpacity: CGFloat = 0.95
        static let headerTitleOpacity: CGFloat = 0.6
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacing) {
            VStack(alignment: .leading, spacing: Constants.headerSpacing) {
                Spacer()
                Text(occurrence.date)
                    .padding(.horizontal)
                    .font(.footnote)
                    .foregroundColor(TokenColors.Text.secondary.swiftUI)
                Divider()
                    .background(TokenColors.Border.subtle.swiftUI)
            }
            .background(TokenColors.Background.surface1.swiftUI)
            .frame(height: Constants.headerHeight)
            
            HStack(alignment: .center) {
                if let chatRoomAvatarViewModel {
                    ChatRoomAvatarView(viewModel: chatRoomAvatarViewModel, size: Constants.avatarSize)
                }
                VStack(alignment: .leading) {
                    Text(occurrence.title)
                        .font(.subheadline)
                    Text(occurrence.time)
                        .font(.caption)
                        .foregroundColor(TokenColors.Text.primary.swiftUI)
                }
            }
            .frame(height: Constants.rowHeight)
        }
        .listRowInsets(EdgeInsets())
    }
}
