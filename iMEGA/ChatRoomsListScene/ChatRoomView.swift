import SwiftUI
import MEGADomain

struct ChatRoomView: View {
    @ObservedObject var viewModel: ChatRoomViewModel
    
    var body: some View {
        Group {
            if #available(iOS 15.0, *) {
                ChatRoomContentView()
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
                ChatRoomContentView()
                    .swipeLeftActions(labels: swipeActionLabels().reversed(), buttonWidth: 65)
                    .actionSheet(isPresented: $viewModel.showDNDTurnOnOptions) {
                        ActionSheet(title: Text(""), buttons: actionSheetButtons())
                    }
            }
        }
        .environmentObject(viewModel)
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

fileprivate struct ChatRoomContentView: View {
    @EnvironmentObject private var viewModel: ChatRoomViewModel
    @Environment(\.layoutDirection) private var layoutDirection
    
    private enum Constants {
        static let viewPadding: CGFloat = 10
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
            
            ChatRoomContentDetailsView()
        }
        .padding(.trailing, Constants.viewPadding)
        .frame(height: Constants.viewHeight)
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
            viewModel.onViewAppear()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }
}

fileprivate struct ChatRoomContentDetailsView: View {
    @EnvironmentObject private var viewModel: ChatRoomViewModel
    
    var body: some View {
        if viewModel.shouldShowUnreadCount || viewModel.existsInProgressCallInChatRoom {
            HStack(spacing: 3) {
                VStack(alignment: .leading, spacing: 4) {
                    ChatRoomContentTitleView()
                    ChatRoomContentDescriptionView()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    if let displayDateString = viewModel.displayDateString {
                        Text(displayDateString)
                            .font(.caption2.bold())
                    }
                    
                    HStack(spacing: 4) {
                        if viewModel.existsInProgressCallInChatRoom {
                            Image(uiImage: Asset.Images.Chat.onACall.image)
                                .resizable()
                                .frame(width: 21, height: 21)
                        }
                        
                        if viewModel.shouldShowUnreadCount {
                            Text(viewModel.unreadCountString)
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        } else {
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 3) {
                    ChatRoomContentTitleView()
                    Spacer()
                    
                    if let displayDateString = viewModel.displayDateString {
                        Text(displayDateString)
                            .font(.caption2)
                    }
                }
                
                HStack(alignment: .top, spacing: 3) {
                    ChatRoomContentDescriptionView()
                    Spacer()
                }
            }
        }
    }
}

fileprivate struct ChatRoomContentTitleView: View {
    @EnvironmentObject private var viewModel: ChatRoomViewModel
    
    var body: some View {
        HStack(spacing: 3) {
            Text(viewModel.chatListItem.title ?? "")
                .font(viewModel.shouldShowUnreadCount ? .subheadline.bold() : .subheadline)
                .lineLimit(1)
            
            if let color = viewModel.chatStatusColor(forChatStatus: viewModel.chatStatus) {
                Color(color)
                    .frame(width: 6, height: 6)
                    .clipShape(Circle())
            }
            
            if viewModel.chatListItem.publicChat == false {
                Image(uiImage: Asset.Images.Chat.privateChat.image)
            }
            
            if viewModel.isMuted {
                Image(uiImage: Asset.Images.Chat.mutedChat.image)
            }
        }
    }
}

fileprivate struct ChatRoomContentDescriptionView: View {
    @EnvironmentObject private var viewModel: ChatRoomViewModel
    
    var body: some View {
        if let hybridDescription = viewModel.hybridDescription {
            HStack(spacing: 0) {
                if let sender = hybridDescription.sender {
                    Text(sender)
                        .font(viewModel.shouldShowUnreadCount ? .caption.bold(): .caption)
                        .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
                }
                
                Image(uiImage: hybridDescription.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                
                Text(hybridDescription.duration)
                    .font(viewModel.shouldShowUnreadCount ? .caption.bold(): .caption)
                    .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
            }
        } else if let description = viewModel.description {
            Text(description)
                .font(viewModel.shouldShowUnreadCount ? .caption.bold(): .caption)
                .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
                .lineLimit(1)
        } else {
            Text("Placeholder")
                .font(.caption)
                .redacted(reason: .placeholder)
        }
    }
}
