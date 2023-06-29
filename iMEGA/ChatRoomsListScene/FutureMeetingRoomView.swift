
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
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 3) {
                    Text(viewModel.title)
                        .font(.subheadline)
                    if viewModel.isRecurring {
                        Image(uiImage: Asset.Images.Meetings.Scheduled.ContextMenu.occurrences.image)
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                    if viewModel.isMuted {
                        Image(uiImage: Asset.Images.Chat.mutedChat.image)
                    }
                }
                
                if viewModel.existsInProgressCallInChatRoom {
                    Text(
                        viewModel.totalCallDuration > 0
                        ? Strings.Localizable.Meetings.Scheduled.Listing.InProgress.descriptionWithDuration(viewModel.totalCallDuration.timeString)
                        : Strings.Localizable.Meetings.Scheduled.Listing.InProgress.description
                    )
                    .font(.caption)
                    .foregroundColor(Color(Colors.Chat.Listing.subtitleText.color))
                } else {
                    HStack(spacing: 3) {
                        Text(viewModel.time)
                            .foregroundColor(Color(Colors.Chat.Listing.meetingTimeTextColor.color))
                            .font(.caption)
                        Text(viewModel.recurrence)
                            .foregroundColor(Color(Colors.Chat.Listing.meetingTimeTextColor.color))
                            .font(.caption)
                    }
                }
            }
            
            Spacer()

            if viewModel.shouldShowUnreadCount || viewModel.existsInProgressCallInChatRoom {
                VStack(alignment: .trailing, spacing: 0) {
                    if let lastMessageTimestamp = viewModel.lastMessageTimestamp {
                        Text(lastMessageTimestamp)
                            .font(.caption2)
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
        .actionSheet(isPresented: $viewModel.showDNDTurnOnOptions) {
            ActionSheet(title: Text(""), buttons: actionSheetButtons())
        }
        .alert(isPresented: $viewModel.showCancelMeetingAlert) {
            let cancelMeetingAlertData = viewModel.cancelMeetingAlertData()
            return Alert(title: Text(cancelMeetingAlertData.title),
                         message: Text(cancelMeetingAlertData.message),
                         primaryButton: .cancel(Text(cancelMeetingAlertData.primaryButtonTitle), action: {
                cancelMeetingAlertData.primaryButtonAction?()
            }), secondaryButton: .default(Text(cancelMeetingAlertData.secondaryButtonTitle))
            )
        }
        .onTapGesture {
            viewModel.showDetails()
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
}
