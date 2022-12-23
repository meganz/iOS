
import SwiftUI

struct FutureMeetingRoomView: View {
    @ObservedObject var viewModel: FutureMeetingRoomViewModel
    
    private enum Constants {
        static let viewHeight: CGFloat = 65
        static let avatarViewSize = CGSize(width: 28, height: 28)
    }

    var body: some View {
        HStack(spacing: 0) {
            if let avatarViewModel = viewModel.chatRoomAvatarViewModel {
                ChatRoomAvatarView(
                    viewModel: avatarViewModel,
                    size: Constants.avatarViewSize
                )
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.title)
                    .font(.subheadline)
                
                Text(viewModel.time)
                    .foregroundColor(Color(Colors.Chat.Listing.meetingTimeTextColor.color))
                    .font(.caption)
            }
            
            if let unreadCount = viewModel.unreadChatCount, unreadCount != 0 {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    if let lastMessageTimestamp = viewModel.lastMessageTimestamp {
                        Text(lastMessageTimestamp)
                            .font(.caption2.bold())
                    }
                    
                    Text(unreadCount > 0 ? "\(unreadCount)" : "\(-unreadCount)+")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            
        }
        .frame(height: Constants.viewHeight)
        .padding(.trailing, 10)
        .contentShape(Rectangle())
        .contextMenu {
            if let contextMenuOptions = viewModel.contextMenuOptions {
                ForEach(contextMenuOptions) { contextMenuOption in
                    Button {
                        contextMenuOption.action()
                    } label: {
                        Label(contextMenuOption.title, image: contextMenuOption.imageName)
                    }
                }
            }
        }
    }
}
