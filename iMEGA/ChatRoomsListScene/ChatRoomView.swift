import SwiftUI
import MEGADomain

@available(iOS 14.0, *)
struct ChatRoomView: View {
    @StateObject var viewModel: ChatRoomViewModel

    var body: some View {
        HStack(spacing: 0) {
            ChatRoomAvatarView(primaryAvatar: viewModel.primaryAvatar, secondaryAvatar: viewModel.secondaryAvatar)
                
            VStack (alignment: .leading, spacing: 4) {
                HStack(spacing: 3) {
                    Text(viewModel.chatListItem.title ?? "")
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    if let statusColor = viewModel.chatStatusColor {
                        Color(statusColor)
                            .frame(width: 6, height: 6)
                            .clipShape(Circle())
                    }
                    
                    if viewModel.chatListItem.publicChat == false {
                        Image(uiImage: Asset.Images.Chat.privateChat.image)
                            .frame(width: 24, height: 24)
                    }
                    
                    Spacer()
                    
                    if let time = viewModel.formattedLastMessageSentDate() {
                        Text(time)
                            .font(.caption2)
                    }
                }
                
                HStack(spacing: 3) {
                    if let hybridDescription = viewModel.hybridDescription {
                        HStack(spacing: 0) {
                            if let sender = hybridDescription.sender {
                                Text(sender)
                                    .font(.caption)
                                    .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
                            }

                            Image(uiImage: hybridDescription.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            
                            Text(hybridDescription.duration)
                                .font(.caption)
                                .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
                        }
                    } else if let description = viewModel.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if viewModel.chatListItem.unreadCount > 0 {
                        Text(String(viewModel.chatListItem.unreadCount))
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(7)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.trailing, 10)
        .frame(height: 65)
        .onAppear {
            Task {
                let chatId = viewModel.chatListItem.chatId
                await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        do {
                            try await viewModel.fetchAvatar()
                        } catch {
                            MEGALogDebug("Unable to fetch avatar for \(chatId) - \(error.localizedDescription)")
                        }
                    }
                    
                    group.addTask {
                        do {
                            try await viewModel.updateDescription()
                        } catch {
                            MEGALogDebug("Unable to load description for \(chatId) - \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 14.0, *)
struct ChatRoomAvatarView: View {
    var primaryAvatar: UIImage?
    var secondaryAvatar: UIImage?
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            if let secondaryAvatar, let primaryAvatar {
                Image(uiImage: secondaryAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .cornerRadius(14)
                    .offset(x: -6, y: -6)
                
                Image(uiImage: primaryAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 28, height: 28)
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(colorScheme == .dark ? Color.black : Color.white, lineWidth: 1)
                    )
                    .offset(x: 6, y: 6)
            } else if let primaryAvatar {
                Image(uiImage: primaryAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)
            } else {
                Image(systemName: "circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .cornerRadius(20)
                    .redacted(reason: .placeholder)
            }
        }
        .frame(width: 60, height: 60)
    }
}


