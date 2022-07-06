import UIKit

extension ChatRoomsViewController {
    @objc func joinActiveCall(withChatRoom chatRoom: MEGAChatRoom) {
        guard let call = MEGASdkManager.sharedMEGAChatSdk().chatCall(forChatId: chatRoom.chatId) else {
            return
        }
        
        let isSpeakerEnabled = AVAudioSession.sharedInstance().mnz_isOutputEqual(toPortType: .builtInSpeaker)
        MeetingContainerRouter(presenter: self,
                               chatRoom: ChatRoomEntity(with: chatRoom),
                               call: CallEntity(with: call),
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
        setNavigationBarButtons()
    }
    
    private func updateSelector(forChatType chatType: MEGAChatType) {
        meetingSelectorButton?.tintColor = chatType == .meeting ?
        .mnz_red(for: traitCollection) : .mnz_primaryGray(for: traitCollection)
        meetingSelectedView?.backgroundColor = chatType == .meeting ?
        UIColor.mnz_red(for: traitCollection) : .black.withAlphaComponent(0.3)
        
        chatSelectorButton?.tintColor = chatType == .nonMeeting ?
        .mnz_red(for: traitCollection) : .mnz_primaryGray(for: traitCollection)
        chatSelectedView?.backgroundColor = chatType == .nonMeeting ?
        UIColor.mnz_red(for: traitCollection) : .black.withAlphaComponent(0.3)
    }
}
