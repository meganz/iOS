import MEGADomain
import UIKit

extension ChatRoomsViewController {
    @objc func joinActiveCall(withChatRoom chatRoom: MEGAChatRoom) {
        guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) else {
            return
        }
        
        let isSpeakerEnabled = AVAudioSession.sharedInstance().mnz_isOutputEqual(toPortType: .builtInSpeaker)
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
        
        selectedButton?.setTitleColor(Colors.Chat.Tabs.chatTabSelectedText.color, for: .normal)
        selectedButton?.titleLabel?.font = .preferredFont(style: .subheadline, weight: .medium)
        normalButton?.setTitleColor(Colors.Chat.Tabs.chatTabNormalText.color, for: .normal)
        normalButton?.titleLabel?.font = .preferredFont(style: .subheadline, weight: .regular)
        selectedView?.backgroundColor = Colors.Chat.Tabs.chatTabSelectedBackground.color
        normalView?.backgroundColor = Colors.Chat.Tabs.chatTabNormalBackground.color
    }
}

extension ChatRoomsViewController: PushNotificationControlProtocol {
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
