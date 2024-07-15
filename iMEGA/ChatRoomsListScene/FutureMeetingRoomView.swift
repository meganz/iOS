import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
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
                        Image(.occurrences)
                            .resizable()
                            .frame(width: 12, height: 12)
                    }
                    if viewModel.isMuted {
                        Image(.mutedChat)
                    }
                }
                
                if viewModel.existsInProgressCallInChatRoom {
                    Text(
                        viewModel.totalCallDuration > 0
                        ? Strings.Localizable.Meetings.Scheduled.Listing.InProgress.descriptionWithDuration(viewModel.totalCallDuration.timeString)
                        : Strings.Localizable.Meetings.Scheduled.Listing.InProgress.description
                    )
                    .font(.caption)
                    .foregroundColor(
                        isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : UIColor.chatListSubtitleText.swiftUI
                    )
                } else {
                    HStack(spacing: 3) {
                        Text(viewModel.time)
                            .foregroundColor(
                                isDesignTokenEnabled ? TokenColors.Button.brand.swiftUI : UIColor.chatListMeetingTimeText.swiftUI
                            )
                            .font(.caption)
                        Text(viewModel.recurrence)
                            .foregroundColor(
                                isDesignTokenEnabled ? TokenColors.Button.brand.swiftUI : UIColor.chatListMeetingTimeText.swiftUI
                            )
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
                            inCallImage
                        }
                        
                        if viewModel.shouldShowUnreadCount {
                            UnreadCountBadgeView(
                                unreadCountString: viewModel.unreadCountString,
                                backgroundColor: isDesignTokenEnabled ? TokenColors.Components.interactive.swiftUI : .red
                            )
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
                        HStack(spacing: 0) {
                            Image(contextMenuOption.image)
                            Text(contextMenuOption.title)
                                .fontWeight(.bold)
                                .font(.title)
                        }
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
                         primaryButton: .default(Text(cancelMeetingAlertData.primaryButtonTitle), action: {
                cancelMeetingAlertData.primaryButtonAction?()
            }), secondaryButton: .cancel(Text(cancelMeetingAlertData.secondaryButtonTitle))
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

    private var inCallImage: some View {
        Image(isDesignTokenEnabled ? .makeCallRoundToken : .onACall)
            .resizable()
            .frame(width: 21, height: 21)
    }
}
