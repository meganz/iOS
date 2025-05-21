import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct ChatRoomView: View {
    @ObservedObject var viewModel: ChatRoomViewModel
    
    var body: some View {
        Group {
            ChatRoomContentView()
                .swipeActions {
                    ForEach(swipeActionLabels()) { label in
                        if let image = MEGAAssets.UIImage.image(named: label.imageName)?
                            .withRenderingMode(.alwaysTemplate)
                            .withTintColor(TokenColors.Icon.onColor) {
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
        if viewModel.isNoteToSelfChatAndEmpty {
            []
        } else if viewModel.chatListItem.isNoteToSelf {
            [
                SwipeActionLabel(
                    imageName: "archiveChatSwipeActionButton",
                    backgroundColor: TokenColors.Support.warning.swiftUI,
                    action: {
                        viewModel.archiveChat()
                    }
                ),
                SwipeActionLabel(
                    imageName: "info",
                    backgroundColor: TokenColors.Support.info.swiftUI,
                    action: {
                        viewModel.chatRoomInfoTapped()
                    }
                )
            ]
        } else {
            [
                SwipeActionLabel(
                    imageName: "archiveChatSwipeActionButton",
                    backgroundColor: TokenColors.Support.warning.swiftUI,
                    action: {
                        viewModel.archiveChat()
                    }
                ),
                SwipeActionLabel(
                    imageName: "moreListChatSwipeActionButton",
                    backgroundColor: TokenColors.Support.info.swiftUI,
                    action: {
                        viewModel.presentMoreOptionsForChat()
                    }
                )
            ]
        }
    }
}

private struct ChatRoomContentView: View {
    @EnvironmentObject private var viewModel: ChatRoomViewModel
    
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
                        HorizontalImageTextLabel(image: contextMenuOption.image, text: contextMenuOption.title)
                    }
                }
            }
        }
        .onTapGesture {
            viewModel.showDetails()
        }
        .task {
            await viewModel.loadChatRoomInfo()
        }
    }
}

private struct ChatRoomContentDetailsView: View {
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
                            inCallImage
                        }
                        
                        if viewModel.shouldShowUnreadCount {
                            UnreadCountBadgeView(
                                unreadCountString: viewModel.unreadCountString,
                                backgroundColor: TokenColors.Components.interactive.swiftUI
                            )
                        }
                    }
                }
            }
        } else {
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 3) {
                    ChatRoomContentTitleView()
                    Spacer()
                    
                    if !viewModel.isNoteToSelfChatAndEmpty, let displayDateString = viewModel.displayDateString {
                        Text(displayDateString)
                            .font(.caption2)
                    }
                    
                    if viewModel.shouldShowNoteToSelfNewFeatureBadge {
                        NewFeatureBadgeView()
                    }
                }
                
                HStack(alignment: .top, spacing: 3) {
                    ChatRoomContentDescriptionView()
                    Spacer()
                }
            }
        }
    }
    
    private var inCallImage: some View {
        MEGAAssets.Image.makeCallRoundToken
            .resizable()
            .frame(width: 21, height: 21)
    }
}

private struct ChatRoomContentTitleView: View {
    @EnvironmentObject private var viewModel: ChatRoomViewModel
    
    var body: some View {
        HStack(spacing: 3) {
            Text(viewModel.chatTitle)
                .font(viewModel.shouldShowUnreadCount ? .subheadline.bold() : .subheadline)
                .lineLimit(1)
            
            if let color = viewModel.chatStatusColor(forChatStatus: viewModel.chatStatus) {
                Color(color)
                    .frame(width: 6, height: 6)
                    .clipShape(Circle())
            }
            
            if viewModel.chatListItem.publicChat == false {
                if !viewModel.chatListItem.isNoteToSelf {
                    MEGAAssets.Image.privateChat
                }
            }
            
            if viewModel.isMuted {
                MEGAAssets.Image.mutedChat
            }
        }
    }
}

private struct ChatRoomContentDescriptionView: View {
    @EnvironmentObject private var viewModel: ChatRoomViewModel
    
    var body: some View {
        if viewModel.chatListItem.meeting, viewModel.existsInProgressCallInChatRoom {
            Text(
                viewModel.totalCallDuration > 0
                ? Strings.Localizable.Meetings.Scheduled.Listing.InProgress.descriptionWithDuration(viewModel.totalCallDuration.timeString)
                : Strings.Localizable.Meetings.Scheduled.Listing.InProgress.description
            )
            .font(.caption)
            .foregroundColor(descriptionTextColor)
        } else if let hybridDescription = viewModel.hybridDescription {
            HStack(spacing: 0) {
                if let sender = hybridDescription.sender {
                    Text(sender)
                        .font(viewModel.shouldShowUnreadCount ? .caption.bold(): .caption)
                        .foregroundColor(descriptionTextColor)
                }
                
                Image(uiImage: hybridDescription.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                
                Text(hybridDescription.duration)
                    .font(viewModel.shouldShowUnreadCount ? .caption.bold(): .caption)
                    .foregroundColor(descriptionTextColor)
            }
        } else if let description = viewModel.description {
            if !viewModel.isNoteToSelfChatAndEmpty {
                Text(description)
                    .font(viewModel.shouldShowUnreadCount ? .caption.bold(): .caption)
                    .foregroundColor(descriptionTextColor)
                    .lineLimit(1)
            }
        } else {
            Text("Placeholder")
                .font(.caption)
                .redacted(reason: .placeholder)
        }
    }
    
    var descriptionTextColor: Color {
        viewModel.shouldShowUnreadCount ? TokenColors.Text.primary.swiftUI : TokenColors.Text.secondary.swiftUI
    }
}
