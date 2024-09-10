import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct MeetingInfoView: View {
    private enum Constants {
        static let spacing: CGFloat = 20
    }
    
    @ObservedObject var viewModel: MeetingInfoViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showWaitingRoomWarningBanner {
                BannerView(
                    config: .init(
                        copy: Strings.Localizable.Meetings.ScheduleMeeting.WaitingRoomWarningBanner.title,
                        theme: .dark,
                        closeAction: viewModel.dismissedWaitingRoomBanner
                    )
                )
                .font(.footnote.bold())
            }
            ScrollView {
                VStack(spacing: Constants.spacing) {
                    MeetingInfoHeaderView()
                        .environmentObject(viewModel)
                    
                    if let chatRoomLinkViewModel = viewModel.chatRoomLinkViewModel, viewModel.isModerator {
                        ChatRoomLinkView(viewModel: chatRoomLinkViewModel)
                    }
                    
                    if viewModel.isUserInChat, let chatRoomNotificationsViewModel = viewModel.chatRoomNotificationsViewModel {
                        ChatRoomNotificationsView(viewModel: chatRoomNotificationsViewModel)
                    }
                    
                    if viewModel.isModerator {
                        MeetingInfoWaitingRoomSettingView(
                            isWaitingRoomOn: $viewModel.isWaitingRoomOn.onChange { enabled in
                                Task {
                                    await viewModel.waitingRoomValueChanged(to: enabled)
                                }
                            },
                            shouldAllowEditingWaitingRoom: viewModel.shouldAllowEditingWaitingRoom
                        )
                        
                        ToggleView(
                            image: .allowNonHostToAddParticipant,
                            text: Strings.Localizable.Meetings.AddContacts.AllowNonHost.message,
                            isOn: $viewModel.isAllowNonHostToAddParticipantsOn.onChange { enabled in
                                Task {
                                    await viewModel.allowNonHostToAddParticipantsValueChanged(to: enabled)
                                }
                            })
                        .background()
                    }
                    
                    DisclosureView(
                        image: .sharedFilesInfo,
                        text: Strings.Localizable.Meetings.Info.sharedFiles) {
                            viewModel.sharedFilesViewTapped()
                        }
                        .background()
                    
                    if viewModel.isModerator {
                        DisclosureView(
                            image: .manageChatHistory,
                            text: Strings.Localizable.Meetings.Info.manageMeetingHistory) {
                                viewModel.manageChatHistoryViewTapped()
                            }
                            .background()
                        
                        KeyRotationView(
                            title: Strings.Localizable.Meetings.Info.KeyRotation.title,
                            rightDetail: Strings.Localizable.enabled,
                            footer: Strings.Localizable.Meetings.Info.KeyRotation.description,
                            isPublicChat: $viewModel.isPublicChat) {
                                viewModel.enableEncryptionKeyRotationViewTapped()
                            }
                    } else if let chatRoomLinkViewModel = viewModel.chatRoomLinkViewModel {
                        ChatRoomLinkNonHostView(viewModel: chatRoomLinkViewModel)
                    }
                    
                    if let chatRoomParticipantsListViewModel = viewModel.chatRoomParticipantsListViewModel {
                        ChatRoomParticipantsListView(viewModel: chatRoomParticipantsListViewModel)
                    }
                    
                    if case let description = viewModel.scheduledMeeting.description, !description.isEmpty {
                        MeetingDescriptionView(description: description)
                            .background()
                    }
                    
                    if viewModel.isUserInChat {
                        LeaveChatButtonView(text: viewModel.isChatPreview() ? Strings.Localizable.close : Strings.Localizable.Meetings.Info.leaveMeeting) {
                            viewModel.leaveGroupViewTapped()
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .background()
    }
}
