import MEGADomain
import MEGAL10n
import UIKit

extension ArchivedChatRoomsViewController {
    @objc func joinActiveCall(withChatRoom chatRoom: MEGAChatRoom) {
        guard let call = MEGAChatSdk.shared.chatCall(forChatId: chatRoom.chatId) else {
            return
        }
        
        let isSpeakerEnabled = AVAudioSession.sharedInstance().isOutputEqualToPortType(.builtInSpeaker)
        MeetingContainerRouter(presenter: self,
                               chatRoom: chatRoom.toChatRoomEntity(),
                               call: call.toCallEntity(),
                               isSpeakerEnabled: isSpeakerEnabled).start()
    }
    
    @objc func configureSelectorView(forChatType chatType: MEGAChatType) {
        chatSelectorButton?.setTitle(Strings.Localizable.Chat.Selector.chat, for: .normal)
        meetingSelectorButton?.setTitle(Strings.Localizable.Chat.Selector.meeting, for: .normal)
        updateSelector(forChatType: chatType)
    }
    
    @objc var chatTypeSelected: MEGAChatType {
        (chatSelectorButton?.isSelected ?? true) ? .nonMeeting : .meeting
    }
    
    @IBAction func meetingSelectorDidTap(_ sender: UIButton) {
        switchSelector(toChatType: .meeting)
    }
    
    @IBAction func chatSelectorDidTap(_ sender: UIButton) {
        switchSelector(toChatType: .nonMeeting)
    }
    
    private func switchSelector(toChatType chatType: MEGAChatType) {
        searchController.isActive = false
        chatSelectorButton?.isSelected = chatType == .nonMeeting
        meetingSelectorButton?.isSelected = chatType == .meeting
        updateSelector(forChatType: chatType)
        reloadData()
        configureNavigationBarButtons()
    }
    
    private func updateSelector(forChatType chatType: MEGAChatType) {
        let (selectedButton, normalButton, selectedView, normalView) = chatType == .meeting ?
        (meetingSelectorButton, chatSelectorButton, meetingSelectedView, chatSelectedView) :
        (chatSelectorButton, meetingSelectorButton, chatSelectedView, meetingSelectedView)
        
        selectedButton?.setTitleColor(MEGAAppColor.Chat.chatTabSelectedText.uiColor, for: .normal)
        selectedButton?.titleLabel?.font = .preferredFont(style: .subheadline, weight: .medium)
        normalButton?.setTitleColor(MEGAAppColor.Chat.chatTabNormalText.uiColor, for: .normal)
        normalButton?.titleLabel?.font = .preferredFont(style: .subheadline, weight: .regular)
        selectedView?.backgroundColor = MEGAAppColor.Chat.chatTabSelectedBackground.uiColor
        normalView?.backgroundColor = MEGAAppColor.Chat.chatTabNormalBackground.uiColor
    }
}

extension ArchivedChatRoomsViewController: PushNotificationControlProtocol {
    func presentAlertController(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
    
    func reloadDataIfNeeded() {
        tableView?.reloadData()
    }
    
    func pushNotificationSettingsLoaded() {
        if chatRoomsType == .default {
            refreshContextMenuBarButton()
        }
    }
}
