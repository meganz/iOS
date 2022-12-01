import SwiftUI

@available(iOS 14.0, *)
struct MeetingInfoHeaderView: View {
    @EnvironmentObject private var viewModel: MeetingInfoViewModel
    @Environment(\.layoutDirection) private var layoutDirection

    private enum Constants {
        static let avatarViewSize = CGSize(width: 40, height: 40)
    }
    
    var body: some View {
        Divider()
        HStack {
            if let chatRoomAvatarViewModel = viewModel.chatRoomAvatarViewModel {
                ChatRoomAvatarView(
                    viewModel: chatRoomAvatarViewModel,
                    size: Constants.avatarViewSize
                )
            }
            
            VStack(alignment: .leading) {
                Text(viewModel.title)
                    .font(.subheadline)
                Text(viewModel.time)
                    .font(.caption)
                    .foregroundColor(Color(UIColor.lightGray))
                Text(viewModel.description)
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.lightGray))
            }
            Spacer()
        }
        Divider()
    }
}


