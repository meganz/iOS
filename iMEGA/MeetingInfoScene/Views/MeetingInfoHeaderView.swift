import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct MeetingInfoHeaderView: View {
    @EnvironmentObject private var viewModel: MeetingInfoViewModel
    @Environment(\.layoutDirection) private var layoutDirection

    private enum Constants {
        static let avatarViewSize = CGSize(width: 40, height: 40)
    }
    
    var body: some View {
        VStack {
            Divider()
            HStack {
                if let chatRoomAvatarViewModel = viewModel.chatRoomAvatarViewModel {
                    ChatRoomAvatarView(
                        viewModel: chatRoomAvatarViewModel,
                        size: Constants.avatarViewSize
                    )
                }
                
                VStack(alignment: .leading) {
                    Text(viewModel.scheduledMeeting.title)
                        .font(.subheadline)
                    Text(viewModel.subtitle)
                        .font(.caption)
                        .foregroundColor(TokenColors.Text.secondary.swiftUI)
                }
                Spacer()
            }
            Divider()
        }
        .background()
    }
}
