import SwiftUI
import MEGADomain

@available(iOS 14.0, *)
struct ChatRoomView: View {
    @ObservedObject var viewModel: ChatRoomViewModel
    
    var body: some View {
        if #available(iOS 15.0, *) {
            ChatRoomContentView(viewModel: viewModel)
                .swipeActions {
                    ForEach(swipeActionLabels()) { label in
                        if let image = UIImage(named: label.imageName)?
                            .withRenderingMode(.alwaysTemplate)
                            .withTintColor(.white) {
                            Button {
                                label.action()
                            } label: {
                                Image(uiImage: image)
                            }
                            .tint(label.backgroundColor)
                        }
                    }
                }
                .confirmationDialog("", isPresented: $viewModel.showDNDTurnOnOptions) {
                    ForEach(viewModel.dndTurnOnOptions(), id: \.self) { dndOption in
                        Button(dndOption.localizedTitle) {
                            viewModel.turnOnDNDOption(dndOption)
                        }
                    }
                }
        } else {
            ChatRoomContentView(viewModel: viewModel)
                .swipeLeftActions(labels: swipeActionLabels().reversed(), buttonWidth: 65)
                .actionSheet(isPresented: $viewModel.showDNDTurnOnOptions) {
                    ActionSheet(title: Text(""), buttons: actionSheetButtons())
                }
        }
    }
    
    private func actionSheetButtons() -> [ActionSheet.Button] {
        var buttons = viewModel.dndTurnOnOptions().map { dndOption in
            ActionSheet.Button.default(Text(dndOption.localizedTitle)) {
                viewModel.turnOnDNDOption(dndOption)
            }
        }
        buttons.append(ActionSheet.Button.cancel())
        return buttons
    }
    
    private func swipeActionLabels() -> [SwipeActionLabel] {
        [
            SwipeActionLabel(
                imageName: "archiveChatSwipeActionButton",
                backgroundColor: Color(Colors.Chat.Listing.archiveSwipeActionBackground.color),
                action: {
                    viewModel.archiveChat()
                }
            ),
            SwipeActionLabel(
                imageName: "moreListChatSwipeActionButton",
                backgroundColor: Color(Colors.Chat.Listing.moreSwipeActionBackground.color),
                action: {
                    viewModel.presentMoreOptionsForChat()
                }
            )
        ]
    }
}

@available(iOS 14.0, *)
struct ChatRoomContentView: View {
    let viewModel: ChatRoomViewModel

    var body: some View {
        HStack(spacing: 0) {
            ChatRoomContentAvatarView(primaryAvatar: viewModel.primaryAvatar,
                                      secondaryAvatar: viewModel.secondaryAvatar)
            ChatRoomContentDetailsView(viewModel: viewModel)
        }
        .padding(.trailing, 10)
        .frame(height: 65)
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
        .onTapGesture {
            viewModel.showDetails()
        }
        .onAppear {
            viewModel.isViewOnScreen = true
        }
        .onDisappear {
            viewModel.isViewOnScreen = false
        }
    }
}

@available(iOS 14.0, *)
struct ChatRoomContentDetailsView: View {
    let viewModel: ChatRoomViewModel
    
    var body: some View {
        if viewModel.chatListItem.unreadCount > 0 {
            HStack(spacing: 3) {
                VStack(alignment: .leading, spacing: 4) {
                    ChatRoomContentTitleView(viewModel: viewModel)
                    ChatRoomContentDescriptionView(viewModel: viewModel)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    if let displayDateString = viewModel.displayDateString {
                        Text(displayDateString)
                            .font(.caption2.bold())
                    }
                    
                    Text(String(viewModel.chatListItem.unreadCount))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(7)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
        } else {
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 3) {
                    ChatRoomContentTitleView(viewModel: viewModel)
                    Spacer()
                    
                    if let displayDateString = viewModel.displayDateString {
                        Text(displayDateString)
                            .font(.caption2)
                    }
                }
                
                HStack(alignment: .top, spacing: 3) {
                    ChatRoomContentDescriptionView(viewModel: viewModel)
                    Spacer()
                }
            }
        }
    }
}

@available(iOS 14.0, *)
struct ChatRoomContentTitleView: View {
    let viewModel: ChatRoomViewModel

    var body: some View {
        HStack(spacing: 3) {
            Text(viewModel.chatListItem.title ?? "")
                .font(viewModel.chatListItem.unreadCount > 0 ? .subheadline.bold() : .subheadline)
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
        }
    }
}

@available(iOS 14.0, *)
struct ChatRoomContentDescriptionView: View {
    let viewModel: ChatRoomViewModel
    
    var body: some View {
        if let hybridDescription = viewModel.hybridDescription {
            HStack(spacing: 0) {
                if let sender = hybridDescription.sender {
                    Text(sender)
                        .font(viewModel.chatListItem.unreadCount > 0 ? .caption.bold(): .caption)
                        .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
                }
                
                Image(uiImage: hybridDescription.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                
                Text(hybridDescription.duration)
                    .font(viewModel.chatListItem.unreadCount > 0 ? .caption.bold(): .caption)
                    .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
            }
        } else if let description = viewModel.description {
            Text(description)
                .font(viewModel.chatListItem.unreadCount > 0 ? .caption.bold(): .caption)
                .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
                .lineLimit(1)
        } else {
            Text("Placeholder")
                .font(.caption)
                .redacted(reason: .placeholder)
        }
    }
}

@available(iOS 14.0, *)
struct ChatRoomContentAvatarView: View {
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

