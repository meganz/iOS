import SwiftUI

struct MeetingInfoView: View {
    @Environment(\.colorScheme) private var colorScheme

    private enum Constants {
        static let spacing: CGFloat = 20
    }
    
    @ObservedObject var viewModel: MeetingInfoViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Constants.spacing) {
                MeetingInfoHeaderView()
                    .environmentObject(viewModel)
                 
                if let chatRoomLinkViewModel = viewModel.chatRoomLinkViewModel {
                    ChatRoomLinkView(viewModel: chatRoomLinkViewModel)
                }
                
                if let chatRoomNotificationsViewModel = viewModel.chatRoomNotificationsViewModel {
                    ChatRoomNotificationsView(viewModel: chatRoomNotificationsViewModel)
                }
                
                ToogleView(
                    image: Asset.Images.Meetings.Info.allowNonHostToAddParticipant.name,
                    text: Strings.Localizable.Meetings.AddContacts.AllowNonHost.message,
                    isOn: $viewModel.isAllowNonHostToAddParticipantsOn) { newValue in
                        viewModel.allowNonHostToAddParticipantsValueChanged(to: newValue)
                    }
                    .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
                
                DisclosureView(
                    image: Asset.Images.Meetings.Info.sharedFilesInfo.name,
                    text: Strings.Localizable.sharedFiles) {
                        viewModel.sharedFilesViewTapped()
                    }
                    .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
                
                DisclosureView(
                    image: Asset.Images.Meetings.Info.manageChatHistory.name,
                    text: Strings.Localizable.manageChatHistory) {
                        viewModel.manageChatHistoryViewTapped()
                    }
                    .background(colorScheme == .dark ? Color(Colors.General.Black._1c1c1e.name) : .white)
                
                KeyRotationView(
                    title: Strings.Localizable.enableEncryptedKeyRotation,
                    rightDetail: Strings.Localizable.enabled,
                    footer: Strings.Localizable.keyRotationIsSlightlyMoreSecureButDoesNotAllowYouToCreateAChatLinkAndNewParticipantsWillNotSeePastMessages,
                    isPublicChat: $viewModel.isPublicChat) {
                        viewModel.enableEncryptionKeyRotationViewTapped()
                    }
                
                if let chatRoomParticipantsListViewModel = viewModel.chatRoomParticipantsListViewModel {
                    ChatRoomParticipantsListView(viewModel: chatRoomParticipantsListViewModel)
                }
                
                if $viewModel.isUserInChat.wrappedValue {
                    LeaveChatButtonView(text: viewModel.isChatPreview() ? Strings.Localizable.close : Strings.Localizable.Meetings.Info.leaveMeeting) {
                        viewModel.leaveGroupViewTapped()
                    }
                }
            }
        }
        .padding(.vertical)
        .background(colorScheme == .dark ? .black : Color(Colors.General.White.f7F7F7.name))
    }
}
