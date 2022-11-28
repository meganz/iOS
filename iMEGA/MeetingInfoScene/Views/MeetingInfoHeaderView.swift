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
            ChatRoomAvatarView(
                viewModel: viewModel.chatRoomAvatarViewModel,
                size: Constants.avatarViewSize
            )
            VStack(alignment: .leading) {
                Text("Book Club - Breasts&Eggs")
                    .font(.subheadline)
                Text("6 July, 09:00-10:00")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.lightGray))
                Text("Natsuko - The narrator role")
                    .font(.caption2)
                    .foregroundColor(Color(UIColor.lightGray))
            }
            Spacer()
        }
        Divider()
    }
}


