import SwiftUI
import MEGADomain

@available(iOS 14.0, *)
struct ChatListItemView: View {
    let chatListItem: ChatListItemEntity

    var body: some View {
        HStack(spacing: 0) {
            ChatListItemImageView(firstImage: Image(systemName: "photo.circle"))
                
            VStack (alignment: .leading, spacing: 4) {
                Text(chatListItem.title ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(chatListItem.lastMessage ?? "")
                    .font(.caption)
                    .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
                    .lineLimit(1)
            }

            Spacer()
            
            VStack (alignment: .trailing, spacing: 4) {
                Text(chatListItem.lastMessageDate.toString())
                    .font(.caption2)
                if chatListItem.unreadCount > 0 {
                    Text(String(chatListItem.unreadCount))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(7)
                        .background(Color.red)
                        .clipShape(Circle())
                } else {
                    Text("")
                }
            }
            .padding(.trailing, 10)

        }
        .frame(height: 65)
    }
}

struct ChatListItemImageView: View {
    let firstImage: Image
    var secondImage: Image?
    
    var body: some View {
        ZStack {
            if let secondImage {
                firstImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .offset(x: -6, y: -6)
                
                secondImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .offset(x: 6, y: 6)
            } else {
                firstImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
            }
        }
        .frame(width: 60, height: 60)
    }
}
